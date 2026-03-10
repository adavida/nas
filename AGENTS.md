# AGENTS.md - Guidelines for Agentic Coding in this Repository

This is a NixOS flake-based home NAS configuration repository. It manages system configuration, services (k3s, OpenLDAP, SFTP, CoreDNS), and Kubernetes app deployments.

## Build/Lint/Test Commands

### Evaluating Configuration
```bash
# Validate the entire flake
nix flake check

# Evaluate a specific NixOS configuration without building
nix eval .#nixosConfigurations.homenas.config.system.build.toplevel

# Evaluate with full trace for debugging
nix eval --show-trace .#nixosConfigurations.homenas.config.system.build.toplevel
```

### Testing with VM
```bash
# Build and run the test VM (homenastest configuration)
nix run .#

# Inside VM, initialize secrets:
init-vm
```

### Deploying Changes
```bash
# Switch to homeNAS configuration (requires root)
sudo nixos-rebuild switch --flake .#homenas

# Switch to test configuration
sudo nixos-rebuild switch --flake .#homenastest

# Build without switching (dry-run)
nixos-rebuild build --flake .#homenas
```

### Formatting
```bash
# Format all Nix files (uses nixfmt-tree as defined in flake)
nix fmt

# Check formatting without modifying
nix fmt -- --check
```

### Secrets Management
```bash
# Generate secrets (run from secrets/ directory)
cd secrets/
make BASE_DOMAIN=nas.local

# Push secrets to k8s cluster
make BASE_DOMAIN=nas.local k8s

# Clean generated secrets
make clean
```

### Kubernetes App Deployment
```bash
# Deploy/update apps via Helm
helm upgrade --install app app --values ./app/values.yaml

# Deploy to test environment
helm upgrade --install app app --values ./app/values-test.yaml

# Generate app secrets
bash app/generate-secret.sh

# Run Nextcloud maintenance commands
kubectl exec -ti deployments/app-nextcloud -- su -s /bin/bash -c './occ maintenance:repair' www-data
```

## Code Style Guidelines

### General Structure
- This is a NixOS flake repository using the `outputs` pattern
- Each service should be in its own file under `service/`
- Machine-specific configurations go in `nas/` and `homenastest/` directories
- Use `common.nix` for shared configuration across all machines

### Nix Language Conventions

#### Imports and Module Arguments
```nix
{
  config,
  pkgs,
  secrets,
  vars,
  ...
}:
```

- Always include `...` (ellipsis) in module arguments to allow flexible argument passing
- Order: `config`, `pkgs`, then custom arguments (`secrets`, `vars`), then `...`
- Use `let` bindings for computed values before the config attribute set

#### Attribute Sets
- Use the shorthand attribute set syntax `{ key = value; }` when possible
- Use 2-space indentation
- Always terminate entries with semicolons
- For multi-line values, use multiline strings with double quotes:
  ```nix
  olcAccess = [
    ''
      {0}to attrs=userPassword
              by self write
              by anonymous auth
              by * none''
  ];
  ```

#### Lists
- Use spaces between elements: `[ item1 item2 item3 ]`
- Multi-line lists should have trailing commas for better diffs

#### Naming Conventions
- File names: kebab-case (e.g., `openldap.nix`)
- Variable names: camelCase (e.g., `baseHost`, `dnsIp`)
- Attribute names: camelCase for NixOS options (e.g., `enable`, `allowedTCPPorts`)
- Nixpkgs packages: lowercase (e.g., `pkgs.openssl`, `pkgs.git`)

### Module Pattern
Each service module should follow this pattern:
```nix
{
  config,
  pkgs,
  secrets,  # custom argument from flake
  vars,     # custom argument from flake
  ...
}:
{
  # networking, systemd services, etc.
}
```

### Configuration Organization
- Keep configuration options grouped logically (networking, services, users, etc.)
- Use imports for modularity
- Document non-obvious configurations with comments (minimal, only when necessary)

### Strings and Paths
- Use absolute paths when referencing files in the same repository: `./relative/path`
- Use string interpolation for dynamic values: `"${secrets}/certs/${vars.base_host}.crt"`
- Paths to nixpkgs packages: `${pkgs.packageName}/bin/executable`

### Error Handling
- Nix will fail fast on type errors - validate with `nix eval` or `nix flake check` frequently
- Use `lib.mkIf`, `lib.mkDefault`, `lib.mkForce` from `nixpkgs.lib` for conditional configuration
- Avoid `builtins.trace` for debugging; use `nix eval --show-trace` instead

### Working with Secrets
- Never commit actual secrets to the repository
- Use the `secrets/` directory with appropriate permissions (0600 for sensitive files)
- Reference secrets via the `secrets` module argument which points to `/etc/nixos/secrets`
- Template files in `app/secrets/test/` use placeholder values for development
- Always regenerate secrets after changing domain: `make BASE_DOMAIN=<domain>`

### Kubernetes/Helm
- Templates go in `app/templates/`
- Values in `app/values.yaml` (base) and `app/values-test.yaml` (test environment)
- Use ConfigMaps for non-sensitive configuration
- Use Secrets for sensitive data (mounted at `/app/secrets` in containers)
- Helm release name is typically `app`

### Testing Changes
1. Always evaluate the configuration before deploying: `nix eval --file flake.nix nixosConfigurations.homenas.config.system.build.toplevel`
2. Test on `homenastest` first if available
3. Run `nix flake check` to validate the flake structure
4. Use `nix run .` to test in a VM before deploying to production

### Common Issues
- Forgetting the `...` in module arguments causes "unexpected attribute" errors
- Relative paths in imports must start with `./` or `../`
- Secret files must exist before `nixos-rebuild switch` - check they are in place
- Certificate paths must be absolute when referencing `${secrets}/certs/`
- After changing `vars.nix`, rebuild both the system and regenerate secrets

### Additional Resources
```bash
nix search nixpkgs <package>  # search packages
nix flake update               # update flake inputs
```
