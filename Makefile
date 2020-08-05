# You can follow the steps below in order to get yourself a local ODC.
# Once running, you can access a Jupyter environment 
# at 'http://localhost' with password 'secretpassword'

# 1. Start your Docker environment
up:
	docker-compose up -d

# 2. Prepare the database
initdb:
	docker-compose exec jupyter datacube -v system init

# 3. Add a product definition for landsat level 1
product:
	docker-compose exec jupyter datacube product add \
		https://raw.githubusercontent.com/opendatacube/datacube-dataset-config/master/products/ls_usgs_level1_scene.yaml

# 3. Index a dataset (just an example, you can change the extents)
index:
	docker-compose exec jupyter bash -c \
		"cd /opt/odc/scripts && python3 ./autoIndex.py \
			--start_date '2013-01-01' \
			--end_date '2020-01-01' \
			--extents '29.63,29.84,45.24,45.10'"
#			--extents '23.39,23.54,46.77,46.72'"
#			--extents '25.42,25.69,47.25,47.14'"
#			--extents '146.30,146.83,-43.54,-43.20'"
#			--extents '25.10,25.26,43.71,43.64'"
#			--extents '32.98674340708594,41.9828951536269,-4.997106940467012,5996881030410326'"
#			--extents '28.4825,30.7947,45.6505,44.4710'"
#			--extents '39.5,39.7,-4.1,-3.9'"
#			--extents '30.41,30.98,28.67,28.13'"
#			--extents '-74.8409, -74.6409,1.0684, 0.8684'"
#			--extents '36.0,36.3,0.49964002,0.74964002'"
#			--extents '-74.91935994831539, -73.30266193148462,0.000134747292617865, 1.077843593651382'"
#			--extents '25.18,25.96,45.53,45.10'"

# Some extra commands to help in managing things.
# Rebuild the image
build:
	docker-compose build

# Start an interactive shell
shell:
	docker-compose exec jupyter bash

# Delete everything
clear:
	docker-compose stop
	docker-compose rm -fs

# Update S3 template (this is owned by Digital Earth Australia)
upload-s3:
	aws s3 cp cube-in-a-box-cloudformation.yml s3://opendatacube-cube-in-a-box/ --acl public-read

# This section can be used to deploy onto CloudFormation instead of the 'magic link'
create-infra:
	aws cloudformation create-stack \
		--region ap-southeast-2 \
		--stack-name odc-test \
		--template-body file://opendatacube-test.yml \
		--parameter file://parameters.json \
		--tags Key=Name,Value=OpenDataCube \
		--capabilities CAPABILITY_NAMED_IAM

update-infra:
	aws cloudformation update-stack \
		--stack-name odc-test \
		--template-body file://opendatacube-test.yml \
		--parameter file://parameters.json \
		--tags Key=Name,Value=OpenDataCube \
		--capabilities CAPABILITY_NAMED_IAM
