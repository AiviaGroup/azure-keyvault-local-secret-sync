import { terraformTemplates } from './terraform-templates';

describe('terraformTemplates', () => {
  it('should work', () => {
    expect(terraformTemplates()).toEqual('terraform-templates');
  });
});
