defmodule CodeSponsorWeb.DashboardController do
  use CodeSponsorWeb, :controller

  defmodule DateRange do
    defstruct first: nil, last: nil
  end

  def index(conn, _params) do

    require Logger

    current_user = conn.assigns.current_user
    end_date     = ~D[2018-03-31]
    start_date   = ~D[2018-03-01]

    impressions_by_day = CodeSponsor.Stats.Impressions.count_by_day(current_user, start_date, end_date)
    all_days =  DateRange(first: start_date, last: end_date)
    Logger.error "ALL DAYS #{inspect all_days}""
    clicks_by_day      = CodeSponsor.Stats.Clicks.count_by_day(current_user, start_date, end_date)
    total_impressions  = Enum.map(impressions_by_day, fn {_, v} -> v end) |> Enum.sum
    total_clicks       = Enum.map(clicks_by_day, fn {_, v} -> v end) |> Enum.sum

    render(conn, "index.html",
      start_date: start_date,
      end_date: end_date,
      impressions_by_day: Poison.encode!(impressions_by_day),
      clicks_by_day: Poison.encode!(clicks_by_day),
      total_impressions: total_impressions,
      total_clicks: total_clicks)
  end
end