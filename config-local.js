define([], function () {
	var configLocal = {};

	configLocal.api = {
		name: 'APP_NAME',
		url: 'http://127.0.0.1:TOMCAT_PORT/APP_NAME/'
	};

	return configLocal;
});
