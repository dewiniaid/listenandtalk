﻿-- PostgreSQL-ish, but this is easily changed.
-- Syntax not yet checked.

DROP SCHEMA listenandtalk CASCADE;
CREATE SCHEMA listenandtalk;
GRANT ALL PRIVILEGES ON SCHEMA listenandtalk TO developer;
SET SESSION AUTHORIZATION developer;
SET SEARCH_PATH=listenandtalk, public;



CREATE TABLE student (
	id SERIAL NOT NULL,
	name_first VARCHAR NOT NULL,
	name_last VARCHAR NOT NULL,

	date_deleted TIMESTAMP WITH TIME ZONE NULL,  -- if non-NULL, this student is "deleted"; date is for future use in case we want to purge records from X years ago.
	PRIMARY KEY(id)
);



CREATE TABLE teacher (
	id SERIAL NOT NULL,
	name_first VARCHAR NOT NULL,
	name_last VARCHAR NOT NULL,
	date_deleted TIMESTAMP WITH TIME ZONE NULL,  -- if non-NULL, this teacher is "deleted"; date is for future use in case we want to purge records from X years ago.

	can_login BOOLEAN NOT NULL DEFAULT TRUE,	-- Don't allow teachers without this to login
	email VARCHAR NULL,	-- Teacher email address for OAuth login.
	-- TODO: Accounts, which might potentially need to be its own table.
	-- If using OAuth, this may just be an email address
	
	PRIMARY KEY(id)
);



CREATE TABLE location (
	-- Lookup table of physical locations 
	id SERIAL NOT NULL,
	name TEXT NOT NULL,

	PRIMARY KEY (id),
	UNIQUE (name)
);



CREATE TABLE attendance_status (
	-- Lookup table of attendance statuses (e.g. Present, Absent, Illness, Not Expected (as a drop-in feature)
	-- May want some additional metadata to simplify any reporting.
	id SERIAL NOT NULL,
	name TEXT NOT NULL,
	
	PRIMARY KEY (id),
	UNIQUE (name)
);



CREATE TABLE course (  -- Because 'class' is a terrible name from a software development perspective.  Also called a "Roster"
	id SERIAL NOT NULL,
	name TEXT NOT NULL,

	teacher_id INT NOT NULL,
	location_id INT NOT NULL,
	
	-- TODO: Track when this class is (so we know when the rostering information is useful)
	start_date DATE NOT NULL,
	end_date DATE NOT NULL,
	-- date_range DATERANGE NOT NULL, 
	-- PostgreSQL has some built-in capabilities for handling ranges more efficiently, but this may be overkill.
	-- I usually maintain this field for efficient querying, but have it updated by trigger -- so backend only
	-- needs to reference it (and the slightly arcane syntax) when it's useful to do so.
	
	-- Course behavior options
	default_attendance_status_id INT NULL,  -- For special classes where we want a particular attendance status to be the default assumption.
	allow_dropins BOOLEAN NOT NULL DEFAULT FALSE,	-- "Drop-in" classes don't maintain a roster, but instead allow an ad-hoc selection 
	-- of a particular student + attendance status.
	
	date_deleted TIMESTAMP WITH TIME ZONE NULL,  -- if non-NULL, this course is "deleted"; date is for future use in case we want to purge records from X years ago.

	PRIMARY KEY(id),
	FOREIGN KEY(teacher_id) REFERENCES teacher(id) ON UPDATE CASCADE ON DELETE RESTRICT,
	FOREIGN KEY(location_id) REFERENCES location(id) ON UPDATE CASCADE ON DELETE RESTRICT,
	FOREIGN KEY(default_attendance_status_id) REFERENCES attendance_status(id) ON UPDATE CASCADE ON DELETE RESTRICT
);



CREATE TABLE course_session (
	-- Tracks an individual session of a course.  (e.g. Monday of this week, vs Monday of next week.)
	-- This table can be generated by database trigger based on some criteria; think of it as a materialized view
	-- rather than a normal table.
	--
	-- Trigger procedures may potentially implement this by bulk-deleting/recreating portions of the table.
	-- Thus, nothing should reference this via foreign key.
	course_id INT NOT NULL,
	date DATE NOT NULL,
	start_time TIMESTAMP WITH TIME ZONE NOT NULL,
	end_time  TIMESTAMP WITH TIME ZONE NOT NULL,

	PRIMARY KEY(course_id, date),
	FOREIGN KEY(course_id) REFERENCES course(id) ON UPDATE CASCADE ON DELETE CASCADE
);



CREATE TABLE attendance (
	-- NOTE: This system does not currently handle any notion of multiple checkins in a particular class per day
	-- This may or may not matter, we should discuss this.
	-- (If a student leaves a class partway through to go to another class, and then returns, should they be re-checked-in?)
	
	-- ASSUMPTIONS:
	-- An attendance entry is expected for a class for a particular day if all of the below conditions are met:
	-- a) The class meets on that day
	-- b) The student's enrollment in the class overlaps the class time
	
	-- A student MAY have an attendance entry for a class, even if the above conditions are not met.  This can happen if
	-- a) It's a drop-in class, and the student is a drop-in.
	-- b) Attendance was entered, but then the student was dropped.  (e.g. a prearranged absence in the future.)
	--
	-- In the case of a), we probably want to still include this record on any reporting.
	-- In the case of b), we probably don't want to include this record because we don't care if a student was going to be 
	-- ... on vacation next week if they're no longer attending.
	
	student_id INT NOT NULL,
	course_id INT NOT NULL,
	date DATE NOT NULL,
	status_id INT NOT NULL,
	
	PRIMARY KEY(student_id, course_id, date),
	FOREIGN KEY(student_id) REFERENCES student(id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY(course_id) REFERENCES course(id) ON UPDATE CASCADE ON DELETE CASCADE
);
