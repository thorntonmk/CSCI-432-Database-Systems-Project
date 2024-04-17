# Grade Book

Grade Book is a MySQL database that manages grades for students attending various courses.

## Installation
MySQL installation is needed to run this software!
If you do not have MySQL installed, you can install it using the command

```bash
sudo apt-get install mysql
```
Once installed, install the database system by first creating the database, importing the structure, and optionally, import the data.
```bash
mysql -u root -p
```
Input your password then
```bash
> create database grade_book
```
exit MySQL then import the files
```bash
mysql -u root -p grade_book < structure.sql
mysql -u root -p grade_book < data.sql
```
And that's it! You have successfully installed Grade Book!

## Usage

Grade Book contains helper routines for performing frequently required tasks.
* calculateminmaxave procedure. Calculates min score, max score and average score of an assignment.
    + **assignment_id** required assignment id for the procedure
* show_course_students procedure. Displays all students in a course
    + **course_id** required course_id from the procedure
* students_add_points / students_add_points_q procedures. Adds points to assignments of students (or students with a "q" in their name)
    + **student_id** required student id for student for whom to make the change
    + **points** required number of points required to add to the total
* students_calculate_grade. Calculates the grade of a student in a course using the provided metrics.
    + **student_id** required is of the student to get the grade.
    + **course_id** required course id to grade the student
## License

[MIT](https://choosealicense.com/licenses/mit/)