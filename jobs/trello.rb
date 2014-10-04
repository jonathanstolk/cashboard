require 'trello'

include Trello

Trello.configure do |config|
  config.developer_public_key = ENV['TRELLO_DEVELOPER_KEY']
  config.member_token = ENV['TRELLO_MEMBER_TOKEN']
end

boards = {
  'SafetyAppsTrello' => '53ce3bcd2d61366b27aa1f55',
}

class MyTrello
  def initialize(widget_id, board_id)
    @widget_id = widget_id
    @board_id = board_id
  end

  def widget_id()
    @widget_id
  end

  def board_id()
    @board_id
  end

  def status_list()
    status = Array.new
    todo = 0
    done = 0
    doing = 0
    Board.find(@board_id).lists.each do |list|
      if (list.name =~ /To Do/)
        todo += list.cards.size
      elsif (list.name =~ /Done/)
        done += list.cards.size
      elsif (list.name =~ /Doing/)
        doing += list.cards.size
      else
        status.push({ label: list.name, value: list.cards.size })
      end
    end
    status = status.sort_by { |k| k[:label] }
    status.unshift({label: 'To Do', value: todo })
    status.unshift({label: 'Doing', value: doing })
    status.unshift({label: 'Done', value: done })
    status
  end
end

@MyTrello = []
boards.each do |widget_id, board_id|
  begin
    @MyTrello.push(MyTrello.new(widget_id, board_id))
  rescue Exception => e
    puts e.to_s
  end
end

SCHEDULER.every '5m', :first_in => 0 do |job|
  @MyTrello.each do |board|
    status = board.status_list()
    send_event(board.widget_id, { :items => status })
  end
end
