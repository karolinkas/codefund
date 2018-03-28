import { Controller } from "stimulus";
import _ from "lodash";
import moment from "moment";
import Chart from "chart.js";

export default class extends Controller {
  static get targets() {
    return ["trafficImpressionsChart", "trafficClicksChart"];
  }

  connect() {
    console.log("DATA");
    console.log(this.element.dataset);
    const impressionsByDay = [1, 2, 3, 5, 1, 2, 3, 5];

    const clicksByDay = [1, 4, 5, 6, 1, 2, 3, 5];

    this.loadTrafficImpressionsChart(impressionsByDay);
    this.loadTrafficClicksChart(clicksByDay);

    console.log("Loaded dashboard");
  }

  strToDate(str) {
    return moment(str);
  }

  loadTrafficImpressionsChart(impressionsByDay) {
    const ctx = this.trafficImpressionsChartTarget.getContext("2d");

    const options = {
      responsive: true,
      scales: {
        xAxes: [
          {
            type: "time",
            time: {
              format: "MM/DD/YYYY",
              unit: "day"
            }
          }
        ]
      }
    };

    const labels = _.map(_.keys(impressionsByDay), this.strToDate);
    this.filterValues = labels;
    console.log("labels");
    console.log(labels);

    const data = {
      labels,
      datasets: [
        {
          label: "Impressions",
          backgroundColor: "rgba(220,220,220,0.2)",
          borderColor: "rgba(220,220,220,1)",
          pointBackgroundColor: "rgba(220,220,220,1)",
          pointBorderColor: "#fff",
          data: _.values(impressionsByDay)
        }
      ]
    };

    return new Chart(ctx, { type: "line", data, options });
  }

  loadTrafficClicksChart(clicksByDay) {
    const ctx = this.trafficClicksChartTarget.getContext("2d");

    const options = {
      responsive: true,
      scales: {
        xAxes: [
          {
            type: "time",
            time: {
              format: "MM/DD/YYYY",
              unit: "day"
            }
          }
        ]
      }
    };

    const labels = _.map(_.keys(clicksByDay), this.strToDate);

    const data = {
      labels,
      datasets: [
        {
          label: "Clicks",
          backgroundColor: "rgba(151,187,205,0.2)",
          borderColor: "rgba(151,187,205,1)",
          pointBackgroundColor: "rgba(151,187,205,1)",
          pointBorderColor: "#fff",
          data: _.values(clicksByDay)
        }
      ]
    };

    return new Chart(ctx, { type: "line", data, options });
  }
}
