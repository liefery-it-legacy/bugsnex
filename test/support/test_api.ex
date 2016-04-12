defmodule Bugsnex.TestApi do

  def start_link do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def subscribe(subscriber_pid) do
    Agent.update(__MODULE__, fn subscribers -> [subscriber_pid | subscribers] end)
  end

  def send_notice(notice) do
    [event] = notice.events
    [exception_data] = event.exceptions
    # if the message of the first exception is "raise_local_error"
    # raise an exception (for testing error case)
    if exception_data.message == "raise_local_error" do
      raise "Expected Error"
    end
    Agent.get(__MODULE__, fn subscribers -> notify_subscribers(subscribers, notice) end)
  end

  def notify_subscribers(subscribers, notice) do
    Enum.map(subscribers, fn subscriber -> send(subscriber, {:notice_sent, notice}) end)
  end

end
