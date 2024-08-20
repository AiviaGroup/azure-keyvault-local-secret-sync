import { infraBicepTemplates } from './infra-bicep-templates';

describe('infraBicepTemplates', () => {
  it('should work', () => {
    expect(infraBicepTemplates()).toEqual('infra-bicep-templates');
  });
});
