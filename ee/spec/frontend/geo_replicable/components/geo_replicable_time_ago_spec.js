import Vuex from 'vuex';
import { createLocalVue, mount } from '@vue/test-utils';
import store from 'ee/geo_replicable/store';
import GeoReplicableTimeAgo from 'ee/geo_replicable/components/geo_replicable_time_ago.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('GeoReplicableTimeAgo', () => {
  let wrapper;

  const propsData = {
    label: 'Test Label',
    dateString: '09-23-1994',
    defaultText: 'Default Text',
  };

  const createComponent = () => {
    wrapper = mount(GeoReplicableTimeAgo, {
      localVue,
      store,
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoReplicableTimeAgo = () => wrapper.find(GeoReplicableTimeAgo);
  const findTimeAgo = () => findGeoReplicableTimeAgo().find(TimeAgo);
  const findDefaultText = () => findGeoReplicableTimeAgo().find('span');

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders GeoReplicableTimeAgo container', () => {
      expect(findGeoReplicableTimeAgo().exists()).toBe(true);
    });

    describe('when dateString exists', () => {
      describe('TimeAgo', () => {
        it('renders', () => {
          expect(findTimeAgo().exists()).toBe(true);
        });

        it('sets time prop', () => {
          expect(findTimeAgo().props().time).toBe(propsData.dateString);
        });

        it(`sets innerHTML as ${propsData.dateString}`, () => {
          expect(findTimeAgo().html()).toMatchSnapshot();
        });
      });

      it('hides DefaultText', () => {
        expect(findDefaultText().exists()).toBe(false);
      });
    });

    describe('when dateString is null', () => {
      beforeEach(() => {
        propsData.dateString = null;
        createComponent();
      });

      it('hides TimeAgo', () => {
        expect(findTimeAgo().exists()).toBe(false);
      });

      describe('DefaultText', () => {
        it('renders', () => {
          expect(findDefaultText().exists()).toBe(true);
        });

        it('sets innerHTML as props.defaultText', () => {
          expect(findDefaultText().html()).toMatchSnapshot();
        });
      });
    });
  });
});
