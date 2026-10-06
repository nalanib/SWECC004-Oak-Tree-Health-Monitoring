"""Pandas: processing student exam data."""
import numpy as np
import pandas as pd

exam_data = {'student_name': ['Daan', 'Emma', 'Katherine', 'Luuk',
                              'Emily', 'Michael', 'Matthew', 'Laura', 'Kevin', 'Sophie'],
             'grade': [8.5, 9, 6.5, np.nan, 6, 5, 7.5, np.nan, 4, 7],
             'attempts': [1, 3, 2, 3, 2, 3, 1, 1, 2, 1],
             'qualify': ['yes', 'yes', 'yes', 'no grade', 'yes', 'no',
                         'yes', 'no grade', 'no', 'yes']}
labels = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j']

PASS_GRADE = 5.5

# 1. Create and display a DataFrame with the index labels
df = pd.DataFrame(exam_data, index=labels)
print("1. Student exam DataFrame:")
print(df, end="\n\n")

# 2. Name and grade of students with more than 2 attempts
print("2. Students with more than 2 attempts:")
print(df.loc[df['attempts'] > 2, ['student_name', 'grade']], end="\n\n")

# 3. Names of students who pass (grade above 5.5)
print("3. Students who pass the exam (grade > 5.5):")
print(df.loc[df['grade'] > PASS_GRADE, 'student_name'].to_list(), end="\n\n")

# 4. Names of students whose grade is missing
missing = df['grade'].isna()
print("4. Students with a missing grade:")
print(df.loc[missing, 'student_name'].to_list(), end="\n\n")

# 5. Mean and standard deviation of the grades (NaN values are skipped)
print("5. Grade statistics:")
print(f"Mean grade:         {df['grade'].mean():.2f}")
print(f"Standard deviation: {df['grade'].std():.2f}", end="\n\n")

# 6-1. Replace the missing grades by a pass grade (6)
df['grade'] = df['grade'].fillna(6)
print("6-1. Missing grades replaced by 6:")
print(df.loc[missing], end="\n\n")

# 6-2. Update the corresponding 'qualify' rows
df.loc[missing, 'qualify'] = np.where(df.loc[missing, 'grade'] > PASS_GRADE, 'yes', 'no')
print("6-2. Updated DataFrame:")
print(df)
