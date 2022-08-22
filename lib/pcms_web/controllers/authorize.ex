defmodule MyAppWeb.Authorize do
  import Phoenix.Controller

  alias MyApp.Accounts
  alias MyApp.Accounts.User
  alias MyApp.Participants
  alias MyApp.Participants.Nomination
  alias MyApp.Settings
  alias MyApp.Regions

  def auth_action(conn, module) do
    conn
    |> get_action()
    |> authorize(get_current_user(conn))
    |> check_auth_success(conn, module)
  end

  defp check_auth_success(%{} = query, conn, module),
    do: apply(module, action_name(conn), [conn, conn.params, query])

  defp check_auth_success(true, conn, module),
    do: apply(module, action_name(conn), [conn, conn.params])

  defp check_auth_success(_, _, _), do: {:error, :unauthorized}

  defp get_action(conn) do
    "#{controller_module(conn)}_#{action_name(conn)}"
    |> String.split("Elixir.MyAppWeb.")
    |> Enum.join("")
  end

  defp get_current_user(%{assigns: %{current_user: current_user}}),
    do: current_user

  ####################################################################
  ##    Controllers
  ####################################################################

  defp authorize("NominationController_index", %User{} = user),
    do: Participants.list_my_nominations_query(user.id, [:bc, :rf, :zc, :af, :nominated_by])

  defp authorize("NominationController_show", %User{} = user),
    do: Participants.list_my_nominations_query(user.id, [:bc, :rf, :zc, :af, :nominated_by])

  defp authorize("NominationController_new", %User{} = user),
    do: %Nomination{nominated_by_id: user.id}

  defp authorize("NominationController_create", %User{} = user),
    do: %{"nominated_by_id" => user.id}

  defp authorize("NominationController_edit", %User{} = user),
    do: Participants.list_my_nominations_query(user.id, [:zc])

  defp authorize("NominationController_update", %User{} = user),
    do: Participants.list_my_nominations_query(user.id, [:zc])


  ####################################################################
  ##    Admin
  ####################################################################

  defp authorize("Admin.NominationController_index", %User{admin: true}),
    do: Participants.list_all_nominations_query()

  defp authorize("Admin.NominationController_show", %User{admin: true}),
    do: Participants.list_all_nominations_query()

  defp authorize("Admin.NominationController_resend_data_submission_link", %User{admin: true}),
    do: Participants.response_awaited_nominations_query()

  ####################################################################
  ##    Fallback choices
  ####################################################################

  defp authorize(action, %User{admin: true}), do: authorize(action)
  defp authorize(_, _), do: :unauthorized

  # Authorise all actions for admin
  defp authorize(_), do: true
end
