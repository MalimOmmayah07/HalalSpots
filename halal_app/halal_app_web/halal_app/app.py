import pyrebase
import json
from flask import Flask, flash, redirect, render_template, request, session, url_for, jsonify
from google.cloud import firestore
import datetime
from datetime import datetime, timedelta
from flask_mysqldb import MySQL
from apscheduler.schedulers.background import BackgroundScheduler

app = Flask(__name__)
app.secret_key = 'deep_fake'

with open('firebase_config.json') as config_file:
    config = json.load(config_file)

firebase = pyrebase.initialize_app(config)
auth = firebase.auth()
storage = firebase.storage()

db = firestore.Client()

app.config['MYSQL_HOST'] = 'localhost'
app.config['MYSQL_USER'] = 'root'
app.config['MYSQL_PASSWORD'] = ''
app.config['MYSQL_DB'] = 'muslim_friendly_certificate_r10'

mysql = MySQL(app)

# Initialize scheduler
scheduler = BackgroundScheduler()
# Login route
@app.route("/")
def login():
    if "is_logged_in" in session and session["is_logged_in"]:
        return redirect(url_for('dashboard'))
    else:
        return render_template("login.html")


# Sign-up route
@app.route("/signup")
def signup():
    if "is_logged_in" in session and session["is_logged_in"]:
        return redirect(url_for('dashboard'))
    else:
        return render_template("signup.html")


# Welcome route
@app.route('/welcome')
def welcome():
    if 'is_logged_in' in session and session['is_logged_in']:
        email = session.get('email')
        name = session.get('name')
        return render_template('layout.html', email=email, name=name)
    else:
        return redirect(url_for('login'))


# Handle login
@app.route("/result", methods=["POST", "GET"])
def result():
    if "is_logged_in" in session and session["is_logged_in"]:
        return redirect(url_for('dashboard'))

    if request.method == "POST":
        email = request.form.get("email")
        password = request.form.get("pass")

        if not email or not password:
            flash("Please provide both email and password.", "warning")
            return render_template('login.html')

        try:
            user = auth.sign_in_with_email_and_password(email, password)
            session["email"] = user["email"]

            user_doc = db.collection("Users").document(session["email"]).get()

            if user_doc.exists:
                user_data = user_doc.to_dict()

                if user_data.get("is_admin", False):
                    session["is_logged_in"] = True
                    session["is_admin"] = True
                    session["fullname"] = user_data.get("fullName")
                    return redirect(url_for('dashboard'))
                else:
                    flash("Access denied. Admin account required.", "danger")
                    return redirect(url_for('login'))
            else:
                flash("User data is incomplete or missing. Contact support.", "danger")
                return redirect(url_for('login'))

        except Exception as e:
            error_message = str(e)
            if "EMAIL_NOT_FOUND" in error_message or "INVALID_PASSWORD" in error_message:
                flash("Invalid email or password. Please try again.", "danger")
            else:
                flash("An unexpected error occurred. Please try again later.", "danger")
            return render_template('login.html')

    return render_template('login.html')


# Display all users (Admin only)
@app.route('/users', methods=['GET'])
def users():
    # Ensure user is logged in and is an admin
    if "is_logged_in" in session and session["is_logged_in"] and session.get("is_admin"):
        # Retrieve users from Firestore
        users = db.collection("Users").stream()
        userlist = [user.to_dict() for user in users]

        # Check if users are found
        if userlist:
            return render_template('admin/users.html', userlist=userlist)
        else:
            flash('No users found!', category='error')
            return redirect(url_for("dashboard"))
    else:
        flash('Authorized Account Only!', category='error')
        return redirect(url_for("dashboard"))
    


# Update user status (Admin only)
@app.route('/update_user_status', methods=['POST'])
def update_user_status():
    # Ensure user is logged in and is an admin
    if "is_logged_in" in session and session["is_logged_in"] and session.get("is_admin"):
        uid = request.json.get('uid')  # Get the user ID from the request
        status = request.json.get('status')  # Get the new status (boolean)

        # Check if the status exists
        if status is not None:  # Ensure a status value is provided
            db.collection('Users').document(uid).update({'status': status})
        else:
            db.collection('Users').document(uid).set({'status': False}, merge=True)
    else:
        return jsonify({"message": "Unauthorized access!"}), 403



    
@app.route('/shops', methods=['GET'])
def shops():
    if "is_logged_in" in session and session["is_logged_in"] and session.get("is_admin"):
        try:
            users_ref = db.collection("Users")
            users = users_ref.stream()  

            shops = [user.to_dict() for user in users if user.to_dict().get("store_name")]

            if shops:
                for shop in shops:
                    items_ref = db.collection("Items").where("postedBy", "==", shop.get("email"))
                    items = items_ref.stream()

                    shop['items'] = [{'id': item.id, **item.to_dict()} for item in items]

                    reviews_ref = db.collection("Reviews").document(shop.get("store_name")).collection("userReviews")
                    reviews = reviews_ref.stream()

                    shop['userReviews'] = [{'id': review.id, **review.to_dict()} for review in reviews]

                    if shop['userReviews']:
                        total_rating = sum([review['rating'] for review in shop['userReviews']])
                        average_rating = total_rating / len(shop['userReviews'])
                        shop['average_rating'] = round(average_rating, 1)  
                    else:
                        shop['average_rating'] = 'N/A' 

                return render_template('view/shop_list.html', shops=shops)
            else:
                flash('No shops found!', category='error')

        except Exception as e:
            flash(f"Error fetching shops: {str(e)}", category='error')
    else:
        flash('Authorized Account Only!', category='error')
        return redirect(url_for("dashboard"))



@app.route('/delete_item/<shop_name>/<item_id>', methods=['POST'])
def delete_item(shop_name, item_id):
    if "is_logged_in" in session and session["is_logged_in"] and session.get("is_admin"):
        try:
            items_ref = db.collection("Items")
            item_ref = items_ref.document(item_id)
            item_ref.delete()

            flash('Item deleted successfully!', category='success')
            return redirect(url_for('shops'))
        except Exception as e:
            flash(f"Error deleting item: {str(e)}", category='error')
            return redirect(url_for('shops'))
    else:
        flash('Unauthorized access!', category='error')
        return redirect(url_for("dashboard"))


@app.route('/delete_review/<shop_name>/<review_id>', methods=['POST'])
def delete_review(shop_name, review_id):
    if "is_logged_in" in session and session["is_logged_in"] and session.get("is_admin"):
        try:
            reviews_ref = db.collection("Reviews").document(shop_name).collection("userReviews")
            review_ref = reviews_ref.document(review_id)
            review_ref.delete()

            flash('Review deleted successfully!', category='success')
            return redirect(url_for('shops'))
        except Exception as e:
            flash(f"Error deleting review: {str(e)}", category='error')
            return redirect(url_for('shops'))
    else:
        flash('Unauthorized access!', category='error')
        return redirect(url_for("dashboard"))

@app.route("/<string:id_user>/update/", methods=['POST', 'GET'])
def update(id_user):
    if "is_logged_in" in session and session["is_logged_in"] and session.get("is_admin"):
        if request.method == 'POST':
            fname = request.form.get('fname')
            lname = request.form.get('lname')
            is_admin = request.form.get('is_admin') == '1'

            db.collection("users").document(id_user).update({
                'fname': fname,
                'lname': lname,
                'is_admin': is_admin
            })

            flash('User updated successfully!', category='success')
            return redirect(url_for("users"))

        else:
            user_doc = db.collection("Users").document(id_user).get()

            if user_doc.exists:
                data = user_doc.to_dict()
                return render_template('admin/update.html', data=data, id_user=id_user)
            else:
                flash('User not found!', category='error')
                return redirect(url_for("dashboard"))
    else:
        flash('Authorized Account Only!', category='error')
        return redirect(url_for("dashboard"))


@app.route('/announcement', methods=['GET', 'POST'])
def announcement():
    if "is_logged_in" in session and session["is_logged_in"]:
        if session.get("is_admin", False): 
            try:
                if request.method == 'POST':
                    datetime_input = request.form.get('datetime')
                    content = request.form.get('content')

                    if datetime_input and content:
                        db.collection("Settings").document("halalAwareness").collection("posts").add({
                            "datetime": datetime_input,
                            "content": content
                        })
                        flash("Announcement added successfully!", "success")
                        return redirect(url_for('announcement'))
                    else:
                        flash("Please fill out all fields.", "error")

                posts = db.collection("Settings").document("halalAwareness").collection("posts").stream()
                posts_data = []
                for post in posts:
                    post_data = post.to_dict()
                    post_data['id'] = post.id  
                    raw_datetime = post_data.get('datetime', '')
                    if raw_datetime:
                        dt_object = datetime.strptime(raw_datetime, "%Y-%m-%dT%H:%M") 
                        post_data['datetime'] = dt_object.strftime("%Y-%m-%d %I:%M %p")
                    posts_data.append(post_data)

                return render_template(
                    'view/announcement.html',
                    posts=posts_data
                )
            except Exception as e:
                return f"An error occurred: {e}", 500
        else:
            return render_template('login.html') 
    else:
        return render_template('login.html')  

@app.route('/<post_id>/edit', methods=['GET', 'POST'])
def edit_announcement(post_id):
    if "is_logged_in" in session and session["is_logged_in"]:
        if session.get("is_admin", False): 
            try:
                if request.method == 'POST':
                    datetime_input = request.form.get('datetime')
                    content = request.form.get('content')

                    if datetime_input and content:
                        db.collection("Settings").document("halalAwareness").collection("posts").document(post_id).update({
                            "datetime": datetime_input,
                            "content": content
                        })
                        flash("Announcement updated successfully!", "success")
                        return redirect(url_for('announcement'))
                    else:
                        flash("Please fill out all fields.", "error")

                post_doc = db.collection("Settings").document("halalAwareness").collection("posts").document(post_id).get()
                if post_doc.exists:
                    post_data = post_doc.to_dict()
                    post_data['id'] = post_id
                    return render_template('view/announcement_edit.html', post=post_data)
                else:
                    flash("Post not found!", "error")
                    return redirect(url_for('announcement'))
            except Exception as e:
                flash(f"An error occurred: {e}", "error")
                return redirect(url_for('announcement'))
        else:
            flash("You are not authorized to perform this action.", "error")
            return redirect(url_for('login'))
    else:
        return redirect(url_for('login'))

from datetime import datetime

@app.route('/posts', methods=['GET'])
def posts():
    if not session.get("is_logged_in"):
        return render_template('login.html') 

    if not session.get("is_admin", False): 
        return render_template('login.html') 

    try:
        # Fetch posts from Firestore
        posts = db.collection("Posts").stream()
        posts_data = []
        for post in posts:
            post_data = post.to_dict()
            post_data['id'] = post.id
            if 'timestamp' in post_data:
                if isinstance(post_data['timestamp'], datetime):
                    timestamp = post_data['timestamp']
                else:
                    timestamp = post_data['timestamp'].to_datetime() 

                post_data['timestamp'] = timestamp.strftime('%Y-%m-%d %I:%M %p') 
            posts_data.append(post_data)

        return render_template(
            'view/shop_post.html',
            posts=posts_data
        )
    except Exception as e:
        return f"An error occurred: {e}", 500


@app.route('/<post_id>/delete_post', methods=['POST'])
def delete_shop_post(post_id):
    if not session.get("is_logged_in") or not session.get("is_admin", False):
        return redirect(url_for('posts'))

    try:
        db.collection("Posts").document(post_id).delete()
        return redirect(url_for('posts'))
    except Exception as e:
        return f"An error occurred while deleting: {e}", 500
    
@app.route('/<post_id>/delete', methods=['POST', 'GET'])
def delete_post(post_id):
    if "is_logged_in" in session and session["is_logged_in"]:
        if session.get("is_admin", False): 
            try:
                db.collection("Settings").document("halalAwareness").collection("posts").document(post_id).delete()
                flash("Post deleted successfully!", "success")
                return redirect(url_for('announcement'))
            except Exception as e:
                flash(f"An error occurred while deleting the post: {e}", "error")
                return redirect(url_for('announcement'))
        else:
            flash("You are not authorized to perform this action.", "error")
            return redirect(url_for('login'))
    else:
        return redirect(url_for('login'))

# Delete a detection
@app.route('/<uid>/delete')
def delete_detection(uid):
    if "is_logged_in" in session and session["is_logged_in"]:
        db.collection("detections").document(uid).delete()
        return redirect(url_for('history'))
    else:
        return render_template('login.html')




def check_and_update_halal_certificates():
    """This function checks the halal certificate numbers and updates the database."""
    with app.app_context(): 
        cur = mysql.connection.cursor()

        cur.execute("SELECT * FROM establishments")
        columns = [desc[0] for desc in cur.description]
        shops = [dict(zip(columns, row)) for row in cur.fetchall()]

        if not shops:
            flash("No shops found!", "warning")  

        cur.close()

        users_ref = db.collection("Users")
        users = users_ref.stream()

        user = [user.to_dict() for user in users if user.to_dict().get("store_name")]

        for shop in shops:
            for u in user:
                if u.get("halal_certificate_number") == shop.get('ID_Number'):
                    user_ref = db.collection("Users").document(u['email']) 
                    user_ref.update({"halal_certificate_verified": True})

scheduler.add_job(func=check_and_update_halal_certificates, trigger="interval", minutes=1)
scheduler.start()

@app.route('/register_list')
def register_list():
    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM establishments")
    columns = [desc[0] for desc in cur.description]
    shops = [dict(zip(columns, row)) for row in cur.fetchall()]

    if not shops:
        flash("No shops found!", "warning")

    cur.close()

    return render_template('view/list_register.html', shops=shops)

# Expiring Shops count function
def get_expiring_shops_count():
    cur = mysql.connection.cursor()
    cur.execute("SELECT COUNT(*) FROM establishments WHERE expiry_date <= CURDATE() - INTERVAL 2 MONTH")  # Adjust query as needed
    count = cur.fetchone()[0]
    cur.close()
    return count

# New route for viewing expiring shops
@app.route('/expiring_shops')
def expiring_shops():
    if "is_logged_in" in session and session["is_logged_in"]:
        cur = mysql.connection.cursor()
        cur.execute("SELECT * FROM establishments WHERE expiry_date <= CURDATE() - INTERVAL 2 MONTH")  # Modify query to fit your table structure
        expiring_shops = cur.fetchall()
        cur.close()
        return render_template('view/expiring_shops.html', expiring_shops=expiring_shops)

@app.route('/dashboard')
def dashboard():
    if "is_logged_in" in session and session["is_logged_in"]:
        # Firebase counts
        announcement_count = db.collection('Settings').document('halalAwareness').collection('posts').get()
        post_count = db.collection('Posts').get()
        shop_count = db.collection('Users').where('type', '==', 'Shop').get()  # Only count 'shop' users
        user_count = db.collection('Users').get()

        # Calculate the counts from the retrieved documents
        announcement_count = len(announcement_count)
        post_count = len(post_count)
        shop_count = len(shop_count)
        user_count = len(user_count)

        # MySQL count for MF Certified shops
        cur = mysql.connection.cursor()
        cur.execute("SELECT COUNT(*) FROM establishments")  # Update this query as needed based on your table structure
        mf_certified_count = cur.fetchone()[0]
        cur.close()

 # Count expiring shops within 2 months
        expiring_shops_count = 0
        try:
            # Adjust this query to match your table structure for expiration dates
            cur = mysql.connection.cursor()
            cur.execute("SELECT * FROM establishments WHERE expiry_date IS NOT NULL")
            expiring_shops = cur.fetchall()

            # Loop through and check if the expiration date is within the next 2 months
            for shop in expiring_shops:
                expiry_date = shop['expiry_date']
                if isinstance(expiry_date, str):  # Ensure the date is in string format
                    expiry_date = datetime.strptime(expiry_date, '%Y-%m-%d')

                if expiry_date and (datetime.now() + timedelta(days=60)) >= expiry_date > datetime.now():
                    expiring_shops_count += 1

            cur.close()
        except Exception as e:
            print(f"Error counting expiring shops: {e}")

        # Print counts for debugging
        print(f"Announcement Count: {announcement_count}")
        print(f"Post Count: {post_count}")
        print(f"Shop Count: {shop_count}")
        print(f"MF Certified Count: {mf_certified_count}")
        print(f"User Count: {user_count}")
        print(f"Expiring Shops Count: {expiring_shops_count}")

        return render_template(
            'dashboard.html',
            announcement_count=announcement_count,
            post_count=post_count,
            shop_count=shop_count,
            mf_certified_count=mf_certified_count,
            user_count=user_count,
            expiring_shops_count=expiring_shops_count
        )
    else:
        return redirect(url_for('login'))

    
@app.route('/shop_post')
def shop_post():
    return render_template('shop_post.html') 
    
# Logout
@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for('login'))


if __name__ == "__main__":
    app.run(debug=True)
