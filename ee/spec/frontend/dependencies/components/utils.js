// eslint-disable-next-line import/prefer-default-export
export const makeDependency = (changes = {}) => ({
  name: 'left-pad',
  version: '0.0.3',
  packager: 'JavaScript (yarn)',
  location: {
    blob_path: '/a-group/a-project/blob/da39a3ee5e6b4b0d3255bfef95601890afd80709/yarn.lock',
    path: 'yarn.lock',
  },
  licenses: [],
  ...changes,
});
