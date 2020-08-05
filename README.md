# Licenta

This project contains a Makefile that can be used to run the Docker containers 
and prepare the database for indexing. 

To run the containers (one PostgreSQL instance and the Jupyter Notebook) you can
use the following command: 
 - make up

To prepare the database (in case this is a fresh deploy) you can use:
 - make initdb
 - make product
 
This will create the DB schema required to index ODC data and add the 
ls_usgs_level1_scene product.

After the containers are running and the DB has been initialized, you can start
indexing data using make index. Please note that you should change the indexing 
extents directly in the Makefile.

Once this is all done, you can connect to the Jupyter Notebook from a browser on
port 81. The deforestation, urbanization and coastal change notebooks can be found
in the following directory: notebooks/odc_sandbox_notebooks/dcal/ 
