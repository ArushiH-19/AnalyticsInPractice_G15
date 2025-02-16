import pandas as pd
from googletrans import Translator
import matplotlib.pyplot as plt
import seaborn as sns

df = pd.read_excel('/Users/abhishekpanda/Downloads/Pineapples/Pest Database.xlsx', sheet_name='Data 1', header=18)
# df.columns = df.iloc[1]  # Set the second row as the new header
# df = df[1:].reset_index(drop=True)  # Remove the old header row and reset index

'''
# translator
translator = Translator()
# Translate a specific column
def translate_text(text):
    try:
        return translator.translate(str(text), src='es', dest='en').text
    except Exception as e:
        return text  # Return original text if translation fails

first_row_translated = df.iloc[0].apply(translate_text)
# Translate only the first row
df.iloc[0] = df.iloc[0].apply(translate_text)
print(first_row_translated)
'''


print(df.head())
print('--------INFO----------')
print(df.info())
print('--------DESCRIBE----------')
print(df.describe())
print('--------NULL----------')
print(df.isnull().sum())
print('--------DUPLICATES----------')
print(df.duplicated().sum())
# print('--------COLUMNS----------')
# print(df.columns)
print('--------SHAPE----------')
print(df.shape)

# REPLACING NULL VALUES WITH LARVA
columns_to_check = ['Thecla_Nymph', 'Thecla_Adult','Huevo_Unhatched egg','Huevo_Hatched/Hatching egg','Soldado_Larva','Soldado_Nymph','Soldado_Adult','Soldado_Pupa','Estado G Soldado 1','Estado G Soldado 2','Estado G Soldado 3','Estado G Soldado 4','Estado G Soldado 5','Scale insect','Rodents','Weevil Damage']

# # Replace missing values 'LARVA'
# Fill missing values in the specified columns with values from 'Thecla_Larva'
df[columns_to_check] = df[columns_to_check].apply(lambda x: x.fillna(df['Thecla_Larva']))

# Replace empty strings with the corresponding value from 'Thecla_Larva'
# df[columns_to_check] = df[columns_to_check].replace('', df['Thecla_Larva'])

# DROP NA
columns_to_keep = ['COS.', 'AREA']
df = df.dropna(subset=[col for col in df.columns if col not in columns_to_keep])

print('--------NULL AGAIN----------')
# print(df.head())
print(df.isnull().sum())
print('--------SHAPE----------')
print(df.shape)


# Ensure 'SAMPLING DATE' is in datetime format
df['SAMPLING DATE'] = pd.to_datetime(df['SAMPLING DATE'], errors='coerce')

df['Thecla_Larva'] = pd.to_numeric(df['Thecla_Larva'], errors='coerce')
df['Huevo_Unhatched egg'] = pd.to_numeric(df['Huevo_Unhatched egg'], errors='coerce')
df['Scale insect'] = pd.to_numeric(df['Scale insect'], errors='coerce')
df['Rodents'] = pd.to_numeric(df['Rodents'], errors='coerce')

# df.to_excel("Pest Database_Clean.xlsx", index=False)

# sns.lineplot(x='SAMPLING DATE', y='Thecla_Larva', data=df, color='blue', errorbar=None, label='Thecla')
# sns.lineplot(x='SAMPLING DATE', y='Huevo_Unhatched egg', data=df, color='red', errorbar=None, label='Huevo')
# sns.lineplot(x='SAMPLING DATE', y='Scale insect', data=df, color='green', errorbar=None, label='Insects')
# sns.lineplot(x='SAMPLING DATE', y='Rodents', data=df, color='orange', errorbar=None, label='Rodents')
# plt.title('Date vs. Pests')
# plt.xticks(rotation=45)
# plt.legend()
# plt.xticks(rotation=45)
# plt.show()


# df1 = df.groupby('WEEK')['Thecla_Larva'].mean().reset_index(name='AVG')
# sns.barplot(x='WEEK', y='AVG', data=df1)
# plt.title('Weekly average')
# plt.xticks(rotation=90)
# plt.show()

df3 = df[df['YEAR'] == 2023]
df2 = df3.groupby('MONTH')['Thecla_Larva'].mean().reset_index(name='AVG')
sns.lineplot(x='MONTH', y='AVG', data=df2)
plt.title('2023 Monthly distribution')
plt.xticks(rotation=90)
plt.show()













