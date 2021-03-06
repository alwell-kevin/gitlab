import { searchBy } from '~/lib/utils/common_utils';

/**
 * Returns array of Epics
 *
 * 1. When state.searchQuery is empty, all Epics are returned.
 * 2. When state.searchQuery has value, Epics list is filtered
 *    using the searchQuery against `iid`, `title`, `reference`
 *    and `url` props of Epic object.
 *
 * @param {object} state
 */
export const groupEpics = state => {
  if (state.searchQuery) {
    return state.epics.filter(epic => {
      const { title, reference, url, iid } = epic;

      // In case user has just pasted ID
      // We need to be specific with the search
      if (Number(state.searchQuery)) {
        return state.searchQuery.includes(iid);
      }

      return searchBy(state.searchQuery, {
        title,
        reference,
        url,
      });
    });
  }
  return state.epics;
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
