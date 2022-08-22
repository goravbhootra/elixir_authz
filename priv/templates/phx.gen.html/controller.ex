defmodule <%= inspect context.web_module %>.<%= inspect Module.concat(schema.web_namespace, schema.alias) %>Controller do
  use <%= inspect context.web_module %>, :controller
  import <%= inspect context.web_module %>.Authorize
  def action(conn, _), do: auth_action(conn, __MODULE__)

  alias <%= inspect context.module %>
  alias <%= inspect schema.module %>

  def index(conn, _params) do
    <%= schema.plural %> = <%= inspect context.alias %>.list_<%= schema.plural %>()
    render(conn, "index.html", <%= schema.plural %>: <%= schema.plural %>)
  end

  def new(conn, _params) do
    changeset = <%= inspect context.alias %>.change_<%= schema.singular %>(%<%= inspect schema.alias %>{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{<%= inspect schema.singular %> => <%= schema.singular %>_params}) do
    case <%= inspect context.alias %>.create_<%= schema.singular %>(<%= schema.singular %>_params) do
      {:ok, <%= schema.singular %>} ->
        render_success(conn, "<%= schema.human_singular %> created successfully",
                             Routes.<%= schema.route_helper %>_path(conn, :show, <%= schema.singular %>)
                            )
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    <%= schema.singular %> = <%= inspect context.alias %>.get_<%= schema.singular %>!(id)
    render(conn, "show.html", <%= schema.singular %>: <%= schema.singular %>)
  end

  def edit(conn, %{"id" => id}) do
    with %<%= inspect schema.alias %>{} = <%= schema.singular %> <- <%= inspect context.alias %>.get_<%= schema.singular %>(id) do
      changeset = <%= inspect context.alias %>.change_<%= schema.singular %>(<%= schema.singular %>)
      render(conn, "edit.html", <%= schema.singular %>: <%= schema.singular %>, changeset: changeset)
    else
      nil -> render_not_found(conn, "<%= schema.human_singular %> not found")
    end
  end

  def update(conn, %{"id" => id, <%= inspect schema.singular %> => <%= schema.singular %>_params}) do
    with %<%= inspect schema.alias %>{} = <%= schema.singular %> <- <%= inspect context.alias %>.get_<%= schema.singular %>(id),
      {:ok, <%= schema.singular %>} <- <%= inspect context.alias %>.update_<%= schema.singular %>(<%= schema.singular %>, <%= schema.singular %>_params) do
        render_success(conn, "<%= schema.human_singular %> updated successfully",
                             Routes.<%= schema.route_helper %>_path(conn, :show, <%= schema.singular %>)
                            )
    else
      nil -> render_not_found(conn, "<%= schema.human_singular %> not found")
      {:error, %Ecto.Changeset{} = changeset} ->
        %<%= inspect schema.alias %>{} = <%= schema.singular %> = <%= inspect context.alias %>.get_<%= schema.singular %>(id)
        render(conn, "edit.html", <%= schema.singular %>: <%= schema.singular %>, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    <%= schema.singular %> = <%= inspect context.alias %>.get_<%= schema.singular %>!(id)
    {:ok, _<%= schema.singular %>} = <%= inspect context.alias %>.delete_<%= schema.singular %>(<%= schema.singular %>)
      render_success(conn, "<%= schema.human_singular %> deleted successfully",
                         Routes.<%= schema.route_helper %>_path(conn, :index)
                  )
  end
end
