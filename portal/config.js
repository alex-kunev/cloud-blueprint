// ⚠️  No real tokens shall be committed to this file!
//
// For GitHub Pages: 
// - inject these values at build time via the deploy-portal workflow
//
// For local development: 
//  - copy this file to config.local.js,
//  - fill in real values, and load that instead.

const CONFIG = {
  githubOwner:        '__GITHUB_OWNER__',
  githubRepo:         '__GITHUB_REPO__',
  githubToken:        '__GITHUB_TOKEN__',
  workflowFile:       'provision.yml',
  defaultBranch:      'main',

  // Optional: base URL for the blob container holding Terraform outputs.
  // e.g. "https://<storage-account>.blob.core.windows.net/provisioner-outputs"
  // Leave empty to skip output display.
  outputsBlobBaseUrl: '',
};
