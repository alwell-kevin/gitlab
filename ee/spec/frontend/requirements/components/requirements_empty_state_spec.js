import { shallowMount } from '@vue/test-utils';

import { GlEmptyState, GlDeprecatedButton } from '@gitlab/ui';
import RequirementsEmptyState from 'ee/requirements/components/requirements_empty_state.vue';
import { FilterState } from 'ee/requirements/constants';

const createComponent = (
  filterBy = FilterState.opened,
  emptyStatePath = '/assets/illustrations/empty-state/requirements.svg',
) =>
  shallowMount(RequirementsEmptyState, {
    propsData: {
      filterBy,
      emptyStatePath,
      requirementsCount: {
        OPENED: 0,
        ARCHIVED: 0,
        ALL: 0,
      },
    },
    stubs: { GlEmptyState },
  });

describe('RequirementsEmptyState', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('emptyStateTitle', () => {
      it('returns string "There are no open requirements" when value of `filterBy` prop is "OPENED" and project has some requirements', () => {
        wrapper.setProps({
          requirementsCount: {
            OPENED: 0,
            ARCHIVED: 2,
            ALL: 2,
          },
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.emptyStateTitle).toBe('There are no open requirements');
        });
      });

      it('returns string "There are no archived requirements" when value of `filterBy` prop is "ARCHIVED" and project has some requirements', () => {
        wrapper.setProps({
          filterBy: FilterState.archived,
          requirementsCount: {
            OPENED: 2,
            ARCHIVED: 0,
            ALL: 2,
          },
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.emptyStateTitle).toBe('There are no archived requirements');
        });
      });

      it('returns a generic string when project has no requirements', () => {
        expect(wrapper.vm.emptyStateTitle).toBe(
          'Requirements allow you to create criteria to check your products against.',
        );
      });
    });

    describe('emptyStateDescription', () => {
      it('returns a generic string when project has no requirements', () => {
        expect(wrapper.vm.emptyStateDescription).toBe(
          'Requirements can be based on users, stakeholders, system, software or anything else you find important to capture.',
        );
      });

      it('returns a null when project has some requirements', () => {
        wrapper.setProps({
          requirementsCount: {
            OPENED: 2,
            ARCHIVED: 0,
            ALL: 2,
          },
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.emptyStateDescription).toBeNull();
        });
      });
    });
  });

  describe('template', () => {
    it('renders empty state element', () => {
      const emptyStateEl = wrapper.find('.empty-state .svg-content img');

      expect(emptyStateEl.exists()).toBe(true);
      expect(emptyStateEl.attributes('alt')).toBe(
        'Requirements allow you to create criteria to check your products against.',
      );
      expect(emptyStateEl.attributes('src')).toBe(
        '/assets/illustrations/empty-state/requirements.svg',
      );
    });

    it('renders new requirement button when project has no requirements', () => {
      const newReqButton = wrapper.find(GlDeprecatedButton);

      expect(newReqButton.exists()).toBe(true);
      expect(newReqButton.text()).toBe('New requirement');
    });

    it('does not render new requirement button when project some requirements', () => {
      wrapper.setProps({
        requirementsCount: {
          OPENED: 2,
          ARCHIVED: 0,
          ALL: 2,
        },
      });

      return wrapper.vm.$nextTick(() => {
        const newReqButton = wrapper.find(GlDeprecatedButton);

        expect(newReqButton.exists()).toBe(false);
      });
    });
  });
});
