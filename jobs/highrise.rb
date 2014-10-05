require 'highrise'

Highrise::Base.site = 'https://changer.highrisehq.com'
Highrise::Base.user = ENV['HIGHRISE_ACCESS_TOKEN']
Highrise::Base.format = :xml

widgets = {
  'Highrise_SafetyApps' => 'Changer Safety Apps',
}

class MyHighrise
  def initialize(widget_id, group)
    @widget_id = widget_id
    @group = group
  end

  def widget_id()
    @widget_id
  end

  def group()
    @group
  end

  def status_list()
    status = Array.new
    deals = Highrise::Deal.find(:all)
    groups = Highrise::Group.find(:all)
    groups.each do |group|
      if (group.name === @group)
        group.users.each do |user|
        end
      end
    end
    deals.each do |deal|
      #puts deal
    end
    status
  end
end

@MyHighrise = []
widgets.each do |widget_id, group|
  begin
    @MyHighrise.push(MyHighrise.new(widget_id, group))
  rescue Exception => e
    puts e.to_s
  end
end

@MyHighriseRecordings = []
(1..10).each do |i|
  @MyHighriseRecordings << { x: i, y: 0 }
end
last_x = @MyHighriseRecordings.last[:x]

SCHEDULER.every '5m', :first_in => 0 do |job|
  @MyHighrise.each do |widget|
    status = widget.status_list()
    #send_event(widget.widget_id, { :items => status })
    deals = Highrise::Deal.find(:all, :conditions => { :category => 4677110 })
    send_event(widget.widget_id, { value: deals.count })
  end

  @MyHighriseRecordings.shift
  last_x += 1
  recordings = Highrise::Recording.find_all_across_pages_since(DateTime.new(2014, 10, 1))
  @MyHighriseRecordings << { x: last_x, y: recordings.count }
  send_event('Highrise_Convergence', points: @MyHighriseRecordings)
end
