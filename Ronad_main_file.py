# This file contains the WSGI configuration required to serve up your
# web application at http://mahdimoradi110.pythonanywhere.com/
# It works by setting the variable 'application' to a WSGI handler of some
# description.
#

# +++++++++++ GENERAL DEBUGGING TIPS +++++++++++
# getting imports and sys.path right can be fiddly!
# We've tried to collect some general tips here:
# https://help.pythonanywhere.com/pages/DebuggingImportError


# +++++++++++ HELLO WORLD +++++++++++
# A little pure-wsgi hello world we've cooked up, just
# to prove everything works.  You should delete this
# code to get your own working.

#import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.cluster import KMeans
import seaborn as sns

ronad_data = pd.read_csv('/home/mahdimoradi110/Ronad_sample_data.csv')
ronad_data.date = pd.to_datetime(ronad_data.date)
ronad_data["weekdays"] = ronad_data.date.dt.day_name()

x1 = ronad_data.groupby(['date', 'weekdays']).count().reset_index()
x2 = x1.groupby('weekdays').order_id.agg(['mean', 'std'])
x2 = x2[['mean', 'std']].round(decimals=2).reset_index()
table_1 = x2.set_index('weekdays').reindex(['Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']).reset_index().to_html()
#-------------------------------------------------------------------------
plt.style.use('dark_background')
fig, ax = plt.subplots(figsize=(10,7))
ax.set_ylabel('Histogram of Demand', size=14)
ax.set_xlabel('Demand', size=14)
ax.hist(x1[x1.weekdays.isin(['Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday'])].order_id, color='red')
ax.hist(x1[x1.weekdays.isin(['Thursday','Friday'])].order_id, color='blue')
ax.grid(linestyle='dotted', linewidth=.8)
plt.savefig(fname='pic_1.jpg')
#-------------------------------------------------------------------------
ronad_data['base_date'] = ronad_data.date.sort_values().tail(1).values[0]
ronad_data['diff'] = (ronad_data.base_date - ronad_data.date)
ronad_data['diff'] = ronad_data['diff'].astype(str)
ronad_data['diff'] = ronad_data['diff'].str.replace(' days', '')
ronad_data['diff'] = ronad_data['diff'].astype(int)
#-------------------------------------------------------------------------
frequency = ronad_data.groupby('user_id').order_id.count().reset_index()
monetary = ronad_data.groupby('user_id').total_purchase.sum().reset_index()
recency = ronad_data.groupby('user_id')['diff'].min().reset_index()
#-------------------------------------------------------------------------
m1 = pd.merge(frequency, monetary, left_on='user_id', right_on='user_id')
m2 = pd.merge(m1, recency, left_on='user_id', right_on='user_id')
m2.columns = ['user_id', 'Frequency', 'Monetary', 'Recency']
#-------------------------------------------------------------------------
clustered = KMeans(n_clusters=5, random_state=0).fit(m2)
m2['cluster'] = clustered.labels_
table_2 = m2.groupby('cluster').mean().round(decimals=2).reset_index().to_html()
#-------------------------------------------------------------------------
plt.style.use('dark_background')
fig_2, ax_2 = plt.subplots(1,1, figsize=(12, 8))
#ax.scatter(m2.Frequency, m2.Recency, c=m2.cluster, alpha=0.6, cmap='jet');
sns.scatterplot(x=m2.Frequency, y=m2.Recency, hue=m2.cluster, palette='tab10', ax=ax_2, edgecolor='None');
ax_2.legend(fontsize=14, title_fontsize=14, title='Clusters')
ax_2.set_xlim(0,20);
ax_2.set_ylim(0,190);
ax_2.set_xlabel('Frequency', size=14)
ax_2.set_ylabel('Recency', size=14)
ax_2.grid(linestyle='dotted', linewidth=.8);
fig_2.savefig('pic_2.jpg');
#-------------------------------------------------------------------------

html = """<html>
<head>
    <title>Ronad | Smart Logistics Services</title>
</head>

<style>
table, th, td {
  border: 1px solid black;
  border-collapse: collapse;
}
</style>

<body>
<h1 style="color:yellow">Welcome to Ronad's world!</h1>
<p style="font-size:20px">
Hello guys, this web page contains informantion regarding the analysis and reports of our E-commerce sales platform, which is as following. <br><br>

The first step is to take a look at the average daily requests and their standard deviations, to see how dispersed the number of requsets are: <br>
</p>
"""

f1 = open(r"my_html.html", 'w')
f1.write(html)
f1.close()

f2 = open(r"my_html.html", 'a')
f2.write("""<div style='float:left' class="column">
            <image src="/static/pic_1.jpg" align="Left" title="Histogram of Demand" alt="Histogram of Demand" width="450" height=250>
            </div>
            <br>
            <br>""")
f2.close()

f3 = open(r"my_html.html", 'a')
f3.write(table_1)
f3.close()

f4 = open(r"my_html.html", 'a')
f4.write("""<br><p style="font-size:20px"><br>The histogram and the table above illustrated the average daily requests both on weekdays and on weekends.<br><br>
            And now the second step is to categorize customers into different clusters based on RFM method. To do this we use the KMeans algorithm:</p><br>""")
f4.close()


f5 = open(r"my_html.html", 'a')
f5.write("""<image src="/static/pic_2.jpg" align="Left" title="Frequency - Recency" alt="Frequency - Recency" width="470" height=270>""")
f5.close()



f6 = open(r"my_html.html", 'a')
f6.write(table_2)
f6.close()


f7 = open(r"my_html.html", 'a')
f7.write("""<br><br><br><br><p style="font-size:20px"><br><br><br><br>To obtain the results above, we first calculated the RFM(recency, frequency, monetary) for users. Then deployed the KMeans algorithm to group the customers. And finally the average RFMs were calculated for each cluster.</p>""")
f7.close()



f8 = open(r"my_html.html", 'a')
f8.write("""</body></html>""")
f8.close()

f9 = open(r"my_html.html", 'r')
final_html = f9.read()
f9.close()
#-------------------------------------------------------------------------

def application(environ, start_response):
    if environ.get('PATH_INFO') == '/':
        status = '200 OK'
        content = final_html
    else:
        status = '404 NOT FOUND'
        content = 'Page not found.'
    response_headers = [('Content-Type', 'text/html'), ('Content-Length', str(len(content)))]
    start_response(status, response_headers)
    yield content.encode('utf8')


# Below are templates for Django and Flask.  You should update the file
# appropriately for the web framework you're using, and then
# click the 'Reload /yourdomain.com/' button on the 'Web' tab to make your site
# live.

# +++++++++++ VIRTUALENV +++++++++++
# If you want to use a virtualenv, set its path on the web app setup tab.
# Then come back here and import your application object as per the
# instructions below


# +++++++++++ CUSTOM WSGI +++++++++++
# If you have a WSGI file that you want to serve using PythonAnywhere, perhaps
# in your home directory under version control, then use something like this:
#
#import sys
#
#path = '/home/mahdimoradi110/path/to/my/app
#if path not in sys.path:
#    sys.path.append(path)
#
#from my_wsgi_file import application  # noqa


# +++++++++++ DJANGO +++++++++++
# To use your own django app use code like this:
#import os
#import sys
#
## assuming your django settings file is at '/home/mahdimoradi110/mysite/mysite/settings.py'
## and your manage.py is is at '/home/mahdimoradi110/mysite/manage.py'
#path = '/home/mahdimoradi110/mysite'
#if path not in sys.path:
#    sys.path.append(path)
#
#os.environ['DJANGO_SETTINGS_MODULE'] = 'mysite.settings'
#
## then:
#from django.core.wsgi import get_wsgi_application
#application = get_wsgi_application()



# +++++++++++ FLASK +++++++++++
# Flask works like any other WSGI-compatible framework, we just need
# to import the application.  Often Flask apps are called "app" so we
# may need to rename it during the import:
#
#
#import sys
#
## The "/home/mahdimoradi110" below specifies your home
## directory -- the rest should be the directory you uploaded your Flask
## code to underneath the home directory.  So if you just ran
## "git clone git@github.com/myusername/myproject.git"
## ...or uploaded files to the directory "myproject", then you should
## specify "/home/mahdimoradi110/myproject"
#path = '/home/mahdimoradi110/path/to/flask_app_directory'
#if path not in sys.path:
#    sys.path.append(path)
#
#from main_flask_app_file import app as application  # noqa

# NB -- many Flask guides suggest you use a file called run.py; that's
# not necessary on PythonAnywhere.  And you should make sure your code
# does *not* invoke the flask development server with app.run(), as it
# will prevent your wsgi file from working.