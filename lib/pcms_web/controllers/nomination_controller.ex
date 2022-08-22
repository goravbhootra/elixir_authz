defmodule MyAppWeb.NominationController do
  use MyAppWeb, :controller
  def action(conn, _), do: MyAppWeb.Authorize.auth_action(conn, __MODULE__)

  import Ecto.Query, only: [from: 2]

  alias MyApp.Repo
  alias MyApp.Regions
  alias MyApp.Participants
  alias MyApp.Participants.Nomination
  alias MyAppWeb.Emailer

  def index(%Plug.Conn{} = conn, %{"statusClass" => "review"} = params, query) do
    from([zone: zone] in query,
      preload: [zone: {zone, :zc}]
    )
    |> Participants.review_pending_nominations_query()
    |> index(conn, params)
  end

  def index(%Plug.Conn{} = conn, params, query) do
    from([zone: zone] in query,
      preload: [zone: {zone, :zc}]
    )
    |> Participants.response_awaited_nominations_query()
    |> index(conn, Map.put(params, "statusClass", "current"))
  end

  def index(%Ecto.Query{} = query, conn, %{"statusClass" => status_class} = params) do
    nominations = Repo.paginate(query, Map.put(params, :page_size, 20))
    render(conn, "index.html", nominations: nominations, status_class: status_class)
  end

  def show(conn, %{"id" => id} = params, query) do
    nomination =
      from([zone: zone] in query,
        preload: [zone: zone]
      )
      |> Participants.get_nomination!(id)

    render(conn, "show.html",
      nomination: nomination,
      zones: list_zones_for_select(conn),
      status_class: params["statusClass"]
    )
  end

  def new(conn, params, nomination) do
    changeset = Participants.change_nomination(nomination)

    render(conn, "new.html",
      changeset: changeset,
      zones: list_zones_for_select(conn),
      status_class: params["statusClass"],
      categories: list_categories_for_select()
    )
  end

  def create(
        %{assigns: %{current_user: current_user}} = conn,
        %{"nomination" => nomination_params} = params,
        attrs
      ) do
    with {:ok, nomination} <- Participants.create_nomination(Map.merge(nomination_params, attrs)) do
      Participants.process_email_notification(nomination, current_user)

      render_success(
        conn,
        "Nomination created successfully",
        Routes.nomination_path(conn, :index)
      )
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html",
          changeset: changeset,
          zones: list_zones_for_select(conn),
          status_class: params["statusClass"],
          categories: list_categories_for_select()
        )
    end
  end

  def edit(conn, %{"id" => id} = params, query) do
    case Participants.get_nomination(query, id) do
      %Nomination{} = nomination ->
        changeset = Participants.change_nomination(nomination)

        render(conn, "edit.html",
          changeset: changeset,
          nomination: nomination,
          zones: list_zones_for_select(conn),
          status_class: params["statusClass"],
          categories: list_categories_for_select()
        )

      nil ->
        render_not_found(conn, "Nomination not found")
    end
  end

  def update(
        conn,
        %{"id" => id, "nomination" => %{"submit" => "withdraw"} = nomination_params},
        query
      ) do
    with %Nomination{} = nomination <- Participants.get_nomination(query, id),
         {:ok, _nomination} <-
           Participants.update_nomination(
             nomination,
             Map.merge(
               Map.take(nomination_params, ["remarks"]),
               %{"status" => 3}
             )
           ) do
      render_success(conn, "Nomination withdrawn", Routes.nomination_path(conn, :index))
    else
      nil ->
        render_not_found(conn, "Nomination not found")

      {:error, %Ecto.Changeset{} = _} ->
        render_error(
          conn,
          "Could not mark the nomination as withdrawn!",
          Routes.nomination_path(conn, :index)
        )
    end
  end

  def update(conn, %{"id" => id, "nomination" => nomination_params}, query) do
    nomination = Participants.get_nomination!(query, id)

    existing_email = nomination.email

    case Participants.update_nomination(
           nomination,
           Map.drop(nomination_params, ["nominated_by_id"])
         ) do
      {:ok, nomination} ->
        if existing_email != nomination_params["email"] do
          Emailer.email_to_nominated_candidate(nomination)
        end

        render_success(
          conn,
          "Nomination updated successfully",
          Routes.nomination_path(conn, :index, statusClass: nomination_params["statusClass"])
        )

      {:error, %Ecto.Changeset{} = changeset} ->
        render(
          conn,
          "edit.html",
          nomination: nomination,
          changeset: changeset,
          zones: list_zones_for_select(conn),
          status_class: nomination_params["statusClass"],
          categories: list_categories_for_select()
        )
    end
  end

  defp list_zones_for_select(conn) do
    Regions.list_zones_for_select(conn)
  end

  defp list_categories_for_select() do
    Participants.nomination_categories()
  end
end
