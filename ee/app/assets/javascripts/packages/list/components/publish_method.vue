<script>
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { GlIcon, GlLink } from '@gitlab/ui';
import { mapGetters } from 'vuex';

export default {
  name: 'PublishMethod',
  components: {
    ClipboardButton,
    GlIcon,
    GlLink,
  },
  props: {
    packageEntity: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapGetters(['getCommitLink']),
    hasPipeline() {
      return Boolean(this.packageEntity.pipeline);
    },
    packageShaShort() {
      return this.packageEntity.pipeline?.sha.substring(0, 8);
    },
    linkToCommit() {
      return this.getCommitLink(this.packageEntity);
    },
  },
};
</script>

<template>
  <div class="d-flex align-items-center text-secondary order-1 order-md-0 mb-md-1">
    <template v-if="hasPipeline">
      <gl-icon name="git-merge" class="mr-1" />
      <strong ref="pipeline-ref" class="mr-1 text-dark">{{ packageEntity.pipeline.ref }}</strong>

      <gl-icon name="commit" class="mr-1" />
      <gl-link ref="pipeline-sha" :href="linkToCommit" class="mr-1">{{ packageShaShort }}</gl-link>

      <clipboard-button
        :text="packageEntity.pipeline.sha"
        :title="__('Copy commit SHA')"
        css-class="border-0 text-secondary py-0 px-1"
      />
    </template>

    <template v-else>
      <gl-icon name="upload" class="mr-1" />
      <strong ref="manual-ref" class="text-dark">{{
        s__('PackageRegistry|Manually Published')
      }}</strong>
    </template>
  </div>
</template>
