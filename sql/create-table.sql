use connectany;

create table if not exists Users (
  id int auto_increment primary key,
  name varchar(100) not null
);

create table if not exists Devices (
  id int auto_increment primary key,
  gid varchar(100) not null unique,
  device_type varchar(100) not null,
  name varchar(100) not null,
  user_id int,
  foreign key(user_id) references Users(id)
);
