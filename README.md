# nagnos

## nsrvs agnostic migration tool

migrate one server to another destination, inside a container and expose the services on destination container.



### Short summary:

Migration of static servers from A-->B is a painfull any difficult operation. But it can be incredibly easy if you containerize the operation from srouce to destination.


The opreation will be done (AS IS MIGRATION) nagnos is the nucleuss-agnostic operation.

**Source system** 

* discovery of services (analyse)
* create a destination container with needed services ----> Destination System
* rsync data from A --> B for database create a sql query after the first dump
* analyse from the logs (latest 2 month) a window for the migration
* up to the moment create all required destination components
* before switch create a pod on source system to take over the tunnelling to destination during the operation time..
* switch over to the new destination..
* keep the source server (pod will forward the traffic to destination server)
* after a while "1-5 days" the source serve will be obsolete..

			  
			  
### CLI driven operation
### tools to be used: Ansible / Terraform
### requirement: Source/Destination root access

PROTOTYPE DOC

Assumption: lets use ansible for orchestration and ignore the analyses, try to figure out if we have a simple wordpress site..
(LAMP )

1.

A enter to source and execute the line 
runme.sh

B enter to destination and execute the line
runme.sh

the connection will be done from A-->B and B<--A VPN to a network where they can see each other..

2.
issue the command in A
nagnos-migrate.sh
this will start the migration from A-->B 
on A analyse
on B create the services inside the container
     rsync data from A->B

3.
issue the command in B
nagnos-migrate.sh make-me-master
this will create a report telling the rest operations:
	will propose a time window where the switching from A-->B will happen
	ask for your approval Y/N
nagnos-migrate.sh make-me-master now
this will again create a report telling what will be done
	!!! Attention!!! will be written to be aware of the opreation
	ask for your approval Y/N
	after the sync is finished the switching will occure without notifying
	
	
services from A will be running on B

nsrvs clinet will be running on the system.. can be also removed 
