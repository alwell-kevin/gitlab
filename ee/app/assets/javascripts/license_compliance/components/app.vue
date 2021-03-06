<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import {
  GlEmptyState,
  GlLoadingIcon,
  GlLink,
  GlIcon,
  GlTab,
  GlTabs,
  GlBadge,
  GlAlert,
} from '@gitlab/ui';
import { LICENSE_LIST } from '../store/constants';
import { LICENSE_MANAGEMENT } from 'ee/vue_shared/license_compliance/store/constants';
import DetectedLicensesTable from './detected_licenses_table.vue';
import PipelineInfo from './pipeline_info.vue';
import LicenseManagement from 'ee/vue_shared/license_compliance/license_management.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  name: 'LicenseComplianceApp',
  components: {
    GlEmptyState,
    GlLoadingIcon,
    GlLink,
    DetectedLicensesTable,
    PipelineInfo,
    GlIcon,
    GlTab,
    GlTabs,
    GlBadge,
    GlAlert,
    LicenseManagement,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    documentationPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      tabIndex: 0,
    };
  },
  computed: {
    ...mapState(LICENSE_LIST, ['initialized', 'licenses', 'reportInfo', 'listTypes']),
    ...mapState(LICENSE_MANAGEMENT, ['managedLicenses']),
    ...mapGetters(LICENSE_LIST, ['isJobSetUp', 'isJobFailed', 'hasPolicyViolations']),
    hasEmptyState() {
      return Boolean(!this.isJobSetUp || this.isJobFailed);
    },
    hasLicensePolicyList() {
      return Boolean(this.glFeatures.licensePolicyList);
    },
    licenseCount() {
      return this.licenses.length;
    },
    policyCount() {
      return this.managedLicenses.length;
    },
    isDetectedProjectTab() {
      return this.tabIndex === 0;
    },
  },
  created() {
    this.fetchLicenses();
  },
  methods: {
    ...mapActions(LICENSE_LIST, ['fetchLicenses']),
  },
};
</script>

<template>
  <gl-loading-icon v-if="!initialized" size="md" class="mt-4" />

  <gl-empty-state
    v-else-if="hasEmptyState"
    :title="s__('Licenses|View license details for your project')"
    :description="
      s__(
        'Licenses|The license list details information about the licenses used within your project.',
      )
    "
    :svg-path="emptyStateSvgPath"
    :primary-button-link="documentationPath"
    :primary-button-text="s__('Licenses|Learn more about license compliance')"
  />

  <div v-else>
    <gl-alert v-if="hasPolicyViolations" class="mt-2" variant="warning" :dismissible="false">
      {{
        s__(
          "Licenses|Detected licenses that are out-of-compliance with the project's assigned policies",
        )
      }}
    </gl-alert>

    <header class="my-3">
      <h2 class="h4 mb-1">
        {{ s__('Licenses|License Compliance') }}
        <gl-link :href="documentationPath" class="vertical-align-middle" target="_blank">
          <gl-icon name="question" />
        </gl-link>
      </h2>

      <pipeline-info
        v-if="isDetectedProjectTab"
        :path="reportInfo.jobPath"
        :timestamp="reportInfo.generatedAt"
      />
      <template v-else>{{ s__('Licenses|Specified policies in this project') }}</template>
    </header>

    <!-- TODO: Remove feature flag -->
    <template v-if="hasLicensePolicyList">
      <gl-tabs v-model="tabIndex" content-class="pt-0">
        <gl-tab>
          <template #title>
            {{ s__('Licenses|Detected in Project') }}
            <gl-badge pill>{{ licenseCount }}</gl-badge>
          </template>

          <detected-licenses-table />
        </gl-tab>

        <gl-tab>
          <template #title>
            {{ s__('Licenses|Policies') }}
            <gl-badge pill>{{ policyCount }}</gl-badge>
          </template>

          <license-management />
        </gl-tab>
      </gl-tabs>
    </template>

    <template v-else>
      <detected-licenses-table class="mt-3" />
    </template>
  </div>
</template>
