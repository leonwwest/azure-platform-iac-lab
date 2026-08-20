.PHONY: fmt validate lint test security verify

fmt:
	terraform -chdir=terraform fmt -check -recursive

validate:
	terraform -chdir=terraform init -backend=false
	terraform -chdir=terraform validate

lint:
	tflint --chdir=terraform --recursive

test:
	terraform -chdir=terraform test
	python3 -m unittest discover -s tests -v

security:
	trivy config --exit-code 1 --severity HIGH,CRITICAL terraform
	checkov -d terraform --quiet --compact

verify: fmt validate lint test security
