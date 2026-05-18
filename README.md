# gha-yamllint

GitHub Action to run yamllint, analyzing your YAML files for potential errors and style issues.

## Usage

```yaml
steps:
  - name: Run yamllint
    uses: albr21/gha-yamllint@1.0.0
    with:
      paths:
        - .github/workflows
        - .github/actions
      config-path: .yamllint.yaml
      fail-on-error: 'true'
```

## Contributing

Check out the [CONTRIBUTING](CONTRIBUTING.md) file for guidelines on how to contribute to this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
