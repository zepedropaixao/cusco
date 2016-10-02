CREATE TABLE relationships
(
	name1 VARCHAR(300) NOT null,
	name2 VARCHAR(300) NOT null,
	KEY name1_index (name1(300)),
	KEY name2_index (name2(300))

) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE people
(
	name VARCHAR(300) NOT null,
	photo_name VARCHAR(300) null,
	KEY name_index (name(300)),
	KEY photo_name_index (photo_name(300))

) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE paths
(
	name1 VARCHAR(300) NOT null,
	name2 VARCHAR(300) NOT null,
	path VARCHAR(500) NOT null,
	distance INT NOT null,
	KEY sp_name1_index (name1(300)),
	KEY sp_name2_index (name2(300)),
	KEY sp_path_index (path(500))

) ENGINE=MyISAM DEFAULT CHARSET=utf8;
