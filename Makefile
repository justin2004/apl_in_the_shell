build:
	docker build --build-arg=uid=`id -u` --build-arg=gid=`id -g` -t justin2004/apl_in_the_shell .

