defmodule Bugsnex.BugsnexCase do
  use ExUnit.CaseTemplate
  alias Bugsnex.{TestApi, NotificationTaskSupervisor}

  setup _tags do
    {:ok, _pid} = TestApi.start_link()
    TestApi.subscribe(self())

    on_exit(fn ->
      Task.Supervisor.children(NotificationTaskSupervisor)
      |> Enum.map(fn child ->
        Task.Supervisor.terminate_child(NotificationTaskSupervisor, child)
      end)
    end)

    :ok
  end
end
