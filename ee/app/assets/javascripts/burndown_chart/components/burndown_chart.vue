<script>
import { GlLineChart } from '@gitlab/ui/dist/charts';
import dateFormat from 'dateformat';
import ResizableChartContainer from '~/vue_shared/components/resizable_chart/resizable_chart_container.vue';
import { s__, __, sprintf } from '~/locale';

export default {
  components: {
    GlLineChart,
    ResizableChartContainer,
  },
  props: {
    startDate: {
      type: String,
      required: true,
    },
    dueDate: {
      type: String,
      required: true,
    },
    openIssuesCount: {
      type: Array,
      required: false,
      default: () => [],
    },
    openIssuesWeight: {
      type: Array,
      required: false,
      default: () => [],
    },
    issuesSelected: {
      type: Boolean,
      required: false,
      default: true,
    },
    showTitle: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      tooltip: {
        title: '',
        content: '',
      },
    };
  },
  computed: {
    dataSeries() {
      let name;
      let data;

      if (this.issuesSelected) {
        name = s__('BurndownChartLabel|Open issues');
        data = this.openIssuesCount;
      } else {
        name = s__('BurndownChartLabel|Open issue weight');
        data = this.openIssuesWeight;
      }

      const series = [
        {
          name,
          data: data.map(d => [new Date(d[0]), d[1]]),
        },
      ];

      if (series[0] && series[0].data.length >= 2) {
        const idealStart = [new Date(this.startDate), data[0][1]];
        const idealEnd = [new Date(this.dueDate), 0];
        const idealData = [idealStart, idealEnd];

        series.push({
          name: __('Guideline'),
          data: idealData,
          silent: true,
          symbolSize: 0,
          lineStyle: {
            color: '#ddd',
            type: 'dashed',
          },
        });
      }

      return series;
    },
    options() {
      return {
        xAxis: {
          name: '',
          type: 'time',
          axisLine: {
            show: true,
          },
        },
        yAxis: {
          name: this.issuesSelected ? __('Total issues') : __('Total weight'),
          axisLine: {
            show: true,
          },
          splitLine: {
            show: false,
          },
        },
        tooltip: {
          trigger: 'item',
          formatter: () => '',
        },
      };
    },
  },
  methods: {
    formatTooltipText(params) {
      const [seriesData] = params.seriesData;
      this.tooltip.title = dateFormat(params.value, 'dd mmm yyyy');

      if (this.issuesSelected) {
        this.tooltip.content = sprintf(__('%{total} open issues'), {
          total: seriesData.value[1],
        });
      } else {
        this.tooltip.content = sprintf(__('%{total} open issue weight'), {
          total: seriesData.value[1],
        });
      }
    },
    showIssueCount() {
      this.issuesSelected = true;
    },
    showIssueWeight() {
      this.issuesSelected = false;
    },
  },
};
</script>

<template>
  <div data-qa-selector="burndown_chart">
    <div v-if="showTitle" class="burndown-header d-flex align-items-center">
      <h3>{{ __('Burndown chart') }}</h3>
    </div>
    <resizable-chart-container class="burndown-chart">
      <gl-line-chart
        slot-scope="{ width }"
        :width="width"
        :data="dataSeries"
        :option="options"
        :format-tooltip-text="formatTooltipText"
      >
        <template slot="tooltipTitle">{{ tooltip.title }}</template>
        <template slot="tooltipContent">{{ tooltip.content }}</template>
      </gl-line-chart>
    </resizable-chart-container>
  </div>
</template>
