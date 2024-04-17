-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Apr 14, 2024 at 11:47 PM
-- Server version: 10.4.28-MariaDB
-- PHP Version: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `grade_book`
--
CREATE DATABASE IF NOT EXISTS `grade_book` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `grade_book`;

DELIMITER $$
--
-- Procedures
--
DROP PROCEDURE IF EXISTS `calculateMinMaxAve`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `calculateMinMaxAve` (IN `assignment_id` INT)   BEGIN
	DECLARE assignment_count integer;
    DECLARE total_assignment integer;
    DECLARE min_assignment integer;
    DECLARE max_assignment integer;
    DECLARE ave_assignment integer;
    
    SET assignment_count = (SELECT COUNT(marks) FROM student_course_coursework WHERE cw_id = assignment_id);
    SET total_assignment = (SELECT SUM(marks) FROM student_course_coursework WHERE cw_id = assignment_id);
    SET @min_assignment = (SELECT MIN(marks) FROM student_course_coursework WHERE cw_id = assignment_id);
    SET @max_assignment = (SELECT MAX(marks) FROM student_course_coursework WHERE cw_id = assignment_id);
    
    SET @ave_assignment = total_assignment/assignment_count;
    
    SELECT @ave_assignment AS `Average_Assignment_Score`, @min_assignment AS `Min_Assignment_Score`,@max_assignment AS `Max_Assignment_Score`;
END$$

DROP PROCEDURE IF EXISTS `show_course_students`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `show_course_students` (IN `course_id` INT)   BEGIN
	SELECT student_courses.st_id AS id, student.st_name AS name, student.st_email AS email, student.st_phone AS phone, student.st_gender AS gender FROM student_courses
    INNER JOIN student on student_courses.st_id = student.st_id
    WHERE student_courses.c_id = course_id;
END$$

DROP PROCEDURE IF EXISTS `students_add_points`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `students_add_points` (IN `assignment_id` INT, IN `points` INT)   BEGIN
	DECLARE total_score integer;
    
    SET total_score = (SELECT cw_total FROM course_coursework WHERE cw_id = assignment_id);
	
    UPDATE student_course_coursework SET marks = (
        CASE WHEN (marks + points) < total_score THEN (marks + points)
        WHEN (marks + points) >= total_score THEN (marks + (points - ((points + marks)- total_score)))
        ELSE (marks + points)
        END)
    WHERE cw_id = assignment_id;
    
END$$

DROP PROCEDURE IF EXISTS `students_add_points_q`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `students_add_points_q` (IN `assignment_id` INT, IN `points` INT)   BEGIN
	DECLARE total_score integer;
    
    SET total_score = (SELECT cw_total FROM course_coursework WHERE cw_id = assignment_id);
	UPDATE student_course_coursework 
    JOIN student_courses ON student_course_coursework.stc_id = student_courses.stc_id
    JOIN student ON student_courses.st_id = student.st_id
    SET student_course_coursework.marks = (
        CASE WHEN (student_course_coursework.marks + points) <= total_score THEN (student_course_coursework.marks + points)
        	WHEN (student_course_coursework.marks + points) > total_score THEN (student_course_coursework.marks + (points - ((points + student_course_coursework.marks)- total_score)))
        ELSE (student_course_coursework.marks + points)
        END)
    WHERE student_course_coursework.cw_id = assignment_id AND student.st_name LIKE '%q%';
    
END$$

DROP PROCEDURE IF EXISTS `students_calculate_grade`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `students_calculate_grade` (IN `student_id` INT, IN `course_id` INT)   BEGIN

DECLARE participation_count integer;
DECLARE participation_present integer;
DECLARE participation_g_total integer;
DECLARE participation_pct integer;
DECLARE assignment_pct integer;
DECLARE project_pct integer;
DECLARE exam_pct integer;

DECLARE assignment_grade decimal(10,1);
DECLARE project_grade decimal(10,1);
DECLARE exam_grade decimal(10,1);
DECLARE student_grade decimal(10,1);

SET participation_count = (SELECT c_weeks FROM course WHERE c_id = course_id);
SET participation_pct = (SELECT c_participation_pts FROM course WHERE c_id = course_id);
SET assignment_pct = (SELECT c_assignment_pts FROM course WHERE c_id = course_id);
SET project_pct = (SELECT c_project_pts FROM course WHERE c_id = course_id);
SET exam_pct = (SELECT c_exam_pts FROM course WHERE c_id = course_id);

SET participation_present = (SELECT COUNT(cp_id) FROM course_participation 
JOIN student_courses ON course_participation.cp_stc_id = student_courses.stc_id 
JOIN student ON student_courses.st_id = student.st_id 
JOIN course ON student_courses.c_id = course.c_id
WHERE student.st_id = student_id AND course.c_id = course_id AND cp_present = TRUE);

SET @participation_g_total = ((participation_present/participation_count)*100)*(participation_pct/100);

SET @assignment_grade = (calculate_category_grade(student_id, course_id, 'assignment', assignment_pct));
SET @project_grade = (calculate_category_grade(student_id, course_id, 'project', project_pct));
SET @exam_grade = (calculate_category_grade(student_id, course_id, 'exam', exam_pct));

SET @student_grade = (@participation_g_total + @assignment_grade + @project_grade + @exam_grade);

SELECT @participation_g_total AS Participation, @assignment_grade AS Assignments, @project_grade AS Projects, @exam_grade AS Exams, @student_grade AS Student_Grade;
END$$

DROP PROCEDURE IF EXISTS `students_calculate_grade_minus_min`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `students_calculate_grade_minus_min` (IN `student_id` INT, IN `course_id` INT)   BEGIN

DECLARE participation_count integer;
DECLARE participation_present integer;
DECLARE participation_g_total integer;
DECLARE participation_pct integer;
DECLARE assignment_pct integer;
DECLARE project_pct integer;
DECLARE exam_pct integer;

DECLARE assignment_grade decimal(10,1);
DECLARE project_grade decimal(10,1);
DECLARE exam_grade decimal(10,1);
DECLARE student_grade decimal(10,1);

SET participation_count = (SELECT c_weeks FROM course WHERE c_id = course_id);
SET participation_pct = (SELECT c_participation_pts FROM course WHERE c_id = course_id);
SET assignment_pct = (SELECT c_assignment_pts FROM course WHERE c_id = course_id);
SET project_pct = (SELECT c_project_pts FROM course WHERE c_id = course_id);
SET exam_pct = (SELECT c_exam_pts FROM course WHERE c_id = course_id);

SET participation_present = (SELECT COUNT(cp_id) FROM course_participation 
JOIN student_courses ON course_participation.cp_stc_id = student_courses.stc_id 
JOIN student ON student_courses.st_id = student.st_id 
JOIN course ON student_courses.c_id = course.c_id
WHERE student.st_id = student_id AND course.c_id = course_id AND cp_present = TRUE);

SET @participation_g_total = ((participation_present/participation_count)*100)*(participation_pct/100);

SET @assignment_grade = (calculate_category_grade_minus_min(student_id, course_id, 'assignment', assignment_pct));
SET @project_grade = (calculate_category_grade_minus_min(student_id, course_id, 'project', project_pct));
SET @exam_grade = (calculate_category_grade_minus_min(student_id, course_id, 'exam', exam_pct));

SET @student_grade = (@participation_g_total + @assignment_grade + @project_grade + @exam_grade);

SELECT @participation_g_total AS Participation, @assignment_grade AS Assignments, @project_grade AS Projects, @exam_grade AS Exams, @student_grade AS Student_Grade;
END$$

--
-- Functions
--
DROP FUNCTION IF EXISTS `calculate_category_grade`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `calculate_category_grade` (`student_id` INT, `course_id` INT, `type` VARCHAR(50), `grade_pct` INT) RETURNS DECIMAL(10,1)  BEGIN
	DECLARE done integer DEFAULT FALSE;
    DECLARE cw_total integer;
    DECLARE cw_id integer;
    DECLARE cw_marks integer;
    DECLARE cw_grade decimal(10,1);
  	DECLARE cur1 CURSOR FOR SELECT cw_id, cw_total FROM course_coursework WHERE cw_c_id = course_id AND cw_course_type = type;
  	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    SET @cw_grade = 0.00;
    OPEN cur1;
    
  	cw_loop: LOOP
    	FETCH cur1 INTO cw_id, cw_total;
    	IF done THEN
      		LEAVE cw_loop;
    	END IF;
    	SET cw_marks = ( SELECT marks FROM student_course_coursework 
                        JOIN student_courses ON student_course_coursework.stc_id = student_courses.stc_id
                        JOIN student ON student_courses.st_id = student.st_id 
                        WHERE student_course_coursework.cw_id = cw_id AND student.st_id = student_id);
        IF cw_marks IS NOT NULL THEN
        	SET @cw_grade = cw_grade + (((cw_marks/cw_total)*100)*(grade_pct/100));
  		END IF;
    END LOOP;

  CLOSE cur1;
  RETURN @cw_grade;
END$$

DROP FUNCTION IF EXISTS `calculate_category_grade_minus_min`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `calculate_category_grade_minus_min` (`course_id` INT, `type` VARCHAR(50), `student_id` INT, `grade_pct` INT) RETURNS DECIMAL(10,1)  BEGIN
	DECLARE done integer DEFAULT FALSE;
    DECLARE cw_total integer;
    DECLARE cw_id integer;
    DECLARE cw_marks integer;
    DECLARE cw_grade decimal(10,1);
    DECLARE min_score decimal(10,1);
    DECLARE grade_score decimal(10,1);
  	DECLARE cur1 CURSOR FOR SELECT cw_id, cw_total FROM course_coursework WHERE cw_c_id = course_id AND cw_course_type = type;
  	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    SET grade_score = 0.0;
    SET min_score = 0.0;
    OPEN cur1;
    
  	cw_loop: LOOP
    	FETCH cur1 INTO cw_id, cw_total;
    	IF done THEN
      		LEAVE cw_loop;
    	END IF;
    	SET cw_marks = (SELECT marks FROM student_course_coursework
                        JOIN student_courses ON student_course_coursework.stc_id = student_courses.stc_id
                        JOIN student ON student_courses.st_id = student.st_id
                        WHERE student_course_coursework.cw_id = cw_id AND student.st_id = student_id);
    	IF cw_marks IS NOT NULL THEN
        	SET cw_grade = ((cw_marks/cw_total)*100)*(grade_pct/100);
        	IF min_score = 0.0 THEN
        		SET min_score = cw_grade;
            	SET grade_score = grade_score + cw_grade;
        	ELSEIF min_score > cw_grade THEN
        		SET min_score = cw_grade;
        	END IF;
        	SET grade_score = grade_score + cw_grade;
        END IF;
  	END LOOP;

  CLOSE cur1;
  SET grade_score = grade_score - min_score;
  RETURN grade_score;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `course`
--

DROP TABLE IF EXISTS `course`;
CREATE TABLE `course` (
  `c_id` int(11) NOT NULL,
  `lec_id` int(11) DEFAULT NULL,
  `c_name` varchar(255) DEFAULT NULL,
  `c_year` int(11) DEFAULT NULL,
  `c_sem` varchar(255) DEFAULT NULL,
  `c_weeks` int(11) DEFAULT NULL,
  `c_participation_pts` int(11) DEFAULT NULL COMMENT 'Percentage of grade for participation',
  `c_assignment_pts` int(11) DEFAULT NULL COMMENT 'Percentage of grade for assignments',
  `c_project_pts` int(11) DEFAULT NULL COMMENT 'Percentage of grade for projects',
  `c_exam_pts` int(11) DEFAULT NULL COMMENT 'Percentage of grade for exams',
  `created_at` date DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Triggers `course`
--
DROP TRIGGER IF EXISTS `total_check_before_insert`;
DELIMITER $$
CREATE TRIGGER `total_check_before_insert` BEFORE INSERT ON `course` FOR EACH ROW BEGIN
DECLARE total_marks integer;
DECLARE participation integer;
DECLARE assignment integer;
DECLARE project integer;
DECLARE exam integer;

SET participation = NEW.c_participation_pts;
SET assignment = NEW.c_assignment_pts;
SET project = NEW.c_project_pts;
SET exam = NEW.c_exam_pts;

SET total_marks = participation + assignment + project + exam;

IF total_marks < 100 THEN
	SIGNAL SQLSTATE '45000'
    	SET MESSAGE_TEXT = 'All categories need to add upto exactly 100', MYSQL_ERRNO = 1001;
ELSEIF total_marks > 100 THEN
	SIGNAL SQLSTATE '45000'
    	SET MESSAGE_TEXT = 'All categories need to add upto exactly 100', MYSQL_ERRNO = 1001;
END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `course_coursework`
--

DROP TABLE IF EXISTS `course_coursework`;
CREATE TABLE `course_coursework` (
  `cw_id` int(11) NOT NULL,
  `cw_c_id` int(11) DEFAULT NULL,
  `cw_course_type` enum('assignment','project','exam') DEFAULT NULL COMMENT 'Allowed types: project, assignment, exam',
  `cw_content` text DEFAULT NULL COMMENT 'course work content',
  `cw_release_date` date DEFAULT NULL,
  `cw_due_date` date DEFAULT NULL,
  `cw_total` int(11) DEFAULT 100,
  `created_at` date DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `course_participation`
--

DROP TABLE IF EXISTS `course_participation`;
CREATE TABLE `course_participation` (
  `cp_id` int(11) NOT NULL,
  `cp_stc_id` int(11) DEFAULT NULL,
  `cp_week` int(11) DEFAULT NULL,
  `cp_present` tinyint(1) DEFAULT NULL,
  `created_at` date DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Triggers `course_participation`
--
DROP TRIGGER IF EXISTS `ensure_participation_not_exceeded`;
DELIMITER $$
CREATE TRIGGER `ensure_participation_not_exceeded` BEFORE INSERT ON `course_participation` FOR EACH ROW BEGIN
DECLARE total_participation integer;
DECLARE total_weeks integer;

SET total_weeks = (SELECT course.c_weeks FROM student_courses 
                  	JOIN course ON student_courses.c_id = course.c_id WHERE student_courses.stc_id = NEW.cp_stc_id);

SET total_participation = (SELECT COUNT(cp_id) FROM course_participation WHERE cp_stc_id = NEW.cp_stc_id);

IF total_participation >= total_weeks THEN
	SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'You have reached the maximum number of attendances for this course';
END IF;

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `lecturer`
--

DROP TABLE IF EXISTS `lecturer`;
CREATE TABLE `lecturer` (
  `lec_id` int(11) NOT NULL,
  `lec_name` varchar(255) DEFAULT NULL,
  `lec_gender` enum('male','female','other') DEFAULT NULL,
  `lec_email` varchar(255) DEFAULT NULL,
  `lec_phone` varchar(255) DEFAULT NULL,
  `created_at` date DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `student`
--

DROP TABLE IF EXISTS `student`;
CREATE TABLE `student` (
  `st_id` int(11) NOT NULL,
  `st_name` varchar(255) DEFAULT NULL,
  `st_email` varchar(255) DEFAULT NULL,
  `st_phone` varchar(255) DEFAULT NULL,
  `st_gender` enum('male','female','other') DEFAULT NULL,
  `created_at` date DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `student_courses`
--

DROP TABLE IF EXISTS `student_courses`;
CREATE TABLE `student_courses` (
  `stc_id` int(11) NOT NULL,
  `st_id` int(11) DEFAULT NULL,
  `c_id` int(11) DEFAULT NULL,
  `created_at` date DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Triggers `student_courses`
--
DROP TRIGGER IF EXISTS `ensure_no_duplicate_student_course`;
DELIMITER $$
CREATE TRIGGER `ensure_no_duplicate_student_course` BEFORE INSERT ON `student_courses` FOR EACH ROW BEGIN
DECLARE course_count integer;

SET course_count = (SELECT COUNT(stc_id) FROM student_courses WHERE st_id = NEW.st_id AND c_id = NEW.c_id);

IF course_count > 0 THEN
	SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'A student can enroll to a course once';
END IF;

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `student_course_coursework`
--

DROP TABLE IF EXISTS `student_course_coursework`;
CREATE TABLE `student_course_coursework` (
  `cw_id` int(11) NOT NULL,
  `stc_id` int(11) NOT NULL,
  `marks` int(11) DEFAULT NULL,
  `created_at` date DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `course`
--
ALTER TABLE `course`
  ADD PRIMARY KEY (`c_id`),
  ADD KEY `lec_id` (`lec_id`);

--
-- Indexes for table `course_coursework`
--
ALTER TABLE `course_coursework`
  ADD PRIMARY KEY (`cw_id`),
  ADD KEY `cw_c_id` (`cw_c_id`);

--
-- Indexes for table `course_participation`
--
ALTER TABLE `course_participation`
  ADD PRIMARY KEY (`cp_id`),
  ADD KEY `cp_stc_id` (`cp_stc_id`);

--
-- Indexes for table `lecturer`
--
ALTER TABLE `lecturer`
  ADD PRIMARY KEY (`lec_id`);

--
-- Indexes for table `student`
--
ALTER TABLE `student`
  ADD PRIMARY KEY (`st_id`);

--
-- Indexes for table `student_courses`
--
ALTER TABLE `student_courses`
  ADD PRIMARY KEY (`stc_id`),
  ADD KEY `st_id` (`st_id`),
  ADD KEY `c_id` (`c_id`);

--
-- Indexes for table `student_course_coursework`
--
ALTER TABLE `student_course_coursework`
  ADD PRIMARY KEY (`cw_id`,`stc_id`),
  ADD KEY `stc_id` (`stc_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `course`
--
ALTER TABLE `course`
  MODIFY `c_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `course_coursework`
--
ALTER TABLE `course_coursework`
  MODIFY `cw_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `course_participation`
--
ALTER TABLE `course_participation`
  MODIFY `cp_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `lecturer`
--
ALTER TABLE `lecturer`
  MODIFY `lec_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `student`
--
ALTER TABLE `student`
  MODIFY `st_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `student_courses`
--
ALTER TABLE `student_courses`
  MODIFY `stc_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `course`
--
ALTER TABLE `course`
  ADD CONSTRAINT `course_ibfk_1` FOREIGN KEY (`lec_id`) REFERENCES `lecturer` (`lec_id`);

--
-- Constraints for table `course_coursework`
--
ALTER TABLE `course_coursework`
  ADD CONSTRAINT `course_coursework_ibfk_1` FOREIGN KEY (`cw_c_id`) REFERENCES `course` (`c_id`);

--
-- Constraints for table `course_participation`
--
ALTER TABLE `course_participation`
  ADD CONSTRAINT `course_participation_ibfk_1` FOREIGN KEY (`cp_stc_id`) REFERENCES `student_courses` (`stc_id`);

--
-- Constraints for table `student_courses`
--
ALTER TABLE `student_courses`
  ADD CONSTRAINT `student_courses_ibfk_1` FOREIGN KEY (`st_id`) REFERENCES `student` (`st_id`),
  ADD CONSTRAINT `student_courses_ibfk_2` FOREIGN KEY (`c_id`) REFERENCES `course` (`c_id`);

--
-- Constraints for table `student_course_coursework`
--
ALTER TABLE `student_course_coursework`
  ADD CONSTRAINT `student_course_coursework_ibfk_1` FOREIGN KEY (`cw_id`) REFERENCES `course_coursework` (`cw_id`),
  ADD CONSTRAINT `student_course_coursework_ibfk_2` FOREIGN KEY (`stc_id`) REFERENCES `student_courses` (`stc_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
