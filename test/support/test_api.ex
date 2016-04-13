defmodule Bugsnex.TestApi do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{crash: false, subscribers: []}, name: __MODULE__)
  end

  def subscribe(subscriber_pid) do
    :ok = GenServer.call(__MODULE__, {:subscribe, subscriber_pid})
  end

  def send_notice(notice) do
    :ok = GenServer.call(__MODULE__, {:send_notice, notice})
  end

  def start_crashing do
    :ok = GenServer.call(__MODULE__, :start_crashing)
  end

  def handle_call({:subscribe, subscriber_pid}, _from, %{subscribers: subscribers} = state) do
    {:reply, :ok, %{state | subscribers: [subscriber_pid | subscribers]}}
  end

  def handle_call({:send_notice, notice}, _from, state = %{crash: true}) do
    notice_subscribers(state.subscribers, notice)
    {:reply, :error, state}
  end
  def handle_call({:send_notice, notice}, _from, state) do
    notice_subscribers(state.subscribers, notice)
    # if the message of the first exception is "raise_local_error"
    # raise an exception (for testing error case)
    [event] = notice.events
    [exception_data] = event.exceptions
    if exception_data.message == "raise_local_error" do
      {:reply, :error, state}
    else
      {:reply, :ok, state}
    end
  end

  def handle_call(:start_crashing, _from, state) do
    {:reply, :ok, %{state | crash: true}}
  end


  def notice_subscribers(subscribers, notice) do
    Enum.map(subscribers, fn subscriber -> send(subscriber, {:notice_sent, notice}) end)
  end
end
