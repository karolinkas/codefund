defmodule CodeFund.Sponsorships do
  @moduledoc """
  The Sponsorships context.
  """

  use CodeFundWeb, :query

  alias CodeFund.Schema.{Sponsorship, Property, Campaign}
  alias CodeFund.Campaigns

  @pagination [page_size: 15]
  @pagination_distance 5

  @doc """
  Paginate the list of sponsorships using filtrex filters.
  """
  def paginate_sponsorships(params \\ %{}) do
    params =
      params
      |> Map.put_new("sort_direction", "desc")
      |> Map.put_new("sort_field", "inserted_at")

    {:ok, sort_direction} = Map.fetch(params, "sort_direction")
    {:ok, sort_field} = Map.fetch(params, "sort_field")

    with {:ok, filter} <- Filtrex.parse_params(filter_config(:sponsorships), params["sponsorship"] || %{}),
        %Scrivener.Page{} = page <- do_paginate_sponsorships(filter, params) do
      {:ok,
        %{
          sponsorships: page.entries,
          page_number: page.page_number,
          page_size: page.page_size,
          total_pages: page.total_pages,
          total_entries: page.total_entries,
          distance: @pagination_distance,
          sort_field: sort_field,
          sort_direction: sort_direction
        }
      }
    else
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end

  defp do_paginate_sponsorships(_filter, params) do
    Sponsorship
    |> order_by(^sort(params))
    |> preload([:campaign, :property, :creative])
    |> paginate(Repo, params, @pagination)
  end

  @doc """
  Returns the list of sponsorships.

  ## Examples

      iex> list_sponsorships()
      [%Sponsorship{}, ...]

  """
  def list_sponsorships do
    Sponsorship
    |> Repo.all
    |> Repo.preload([:property, :campaign, :creative])
  end

  @doc """
  Gets a single sponsorship.

  Raises `Ecto.NoResultsError` if the Sponsorship does not exist.

  ## Examples

      iex> get_sponsorship!(123)
      %Sponsorship{}

      iex> get_sponsorship!(456)
      ** (Ecto.NoResultsError)

  """
  def get_sponsorship!(id) do
    Sponsorship
    |> Repo.get!(id)
    |> Repo.preload([:property, :campaign, :creative])
  end

  def get_sponsorship_for_property(%Property{} = property) do
    sponsorship = Repo.preload(property, :sponsorship).sponsorship
    case confirm_existing_sponsorship(property, sponsorship) do
      %Sponsorship{} = sponsorship -> sponsorship |> Repo.preload([:campaign, :property, :creative])
      nil -> nil
    end
  end

  def confirm_existing_sponsorship(%Property{} = property, nil) do
    # Determine if there is an available campaign
    campaign =
      Repo.one(
        from c in Campaign,
        join: s in assoc(c, :sponsorships),
        join: b in assoc(c, :budgeted_campaign),
        where: c.status == 1,
        where: s.property_id == ^property.id,
        where: b.day_remain > 0,
        where: b.month_remain > 0,
        where: b.total_remain > 0,
        order_by: [desc: c.bid_amount]
      )

    cond do
      campaign == nil ->
        Property.changeset(property, %{sponsorship_id: nil}) |> Repo.update
        nil
      true ->
        sponsorship =
          Repo.one(
            from s in Sponsorship,
            where: s.property_id == ^property.id,
            where: s.campaign_id == ^campaign.id
          )
        Property.changeset(property, %{sponsorship_id: sponsorship.id}) |> Repo.update
        sponsorship
    end
  end

  def confirm_existing_sponsorship(%Property{} = property, %Sponsorship{} = sponsorship) do
    campaign = Repo.preload(sponsorship, :campaign).campaign |> Repo.preload(:budgeted_campaign)
    case Campaigns.has_remaining_budget?(campaign) do
      true -> sponsorship
      false -> confirm_existing_sponsorship(property, nil)
    end
  end



  @doc """
  Creates a sponsorship.

  ## Examples

      iex> create_sponsorship(%{field: value})
      {:ok, %Sponsorship{}}

      iex> create_sponsorship(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_sponsorship(attrs \\ %{}) do
    %Sponsorship{}
    |> Sponsorship.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a sponsorship.

  ## Examples

      iex> update_sponsorship(sponsorship, %{field: new_value})
      {:ok, %Sponsorship{}}

      iex> update_sponsorship(sponsorship, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_sponsorship(%Sponsorship{} = sponsorship, attrs) do
    sponsorship
    |> Sponsorship.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Sponsorship.

  ## Examples

      iex> delete_sponsorship(sponsorship)
      {:ok, %Sponsorship{}}

      iex> delete_sponsorship(sponsorship)
      {:error, %Ecto.Changeset{}}

  """
  def delete_sponsorship(%Sponsorship{} = sponsorship) do
    from(
      p in Property,
      join: s in Sponsorship, on: p.sponsorship_id == s.id
    )
    |> update([set: [sponsorship_id: nil]])
    |> Repo.update_all([])
    Repo.delete(sponsorship)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking sponsorship changes.

  ## Examples

      iex> change_sponsorship(sponsorship)
      %Ecto.Changeset{source: %Sponsorship{}}

  """
  def change_sponsorship(%Sponsorship{} = sponsorship) do
    Sponsorship.changeset(sponsorship, %{})
  end

  defp filter_config(:sponsorships) do
    defconfig do
      text :redirect_url
      number :bid_amount
    end
  end
end
