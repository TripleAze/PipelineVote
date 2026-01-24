# VotingApp
A full-stack voting application that allows users to cast votes on different options and view real-time results. This project demonstrates the integration of Java (JSP/Servlets) with a MySQL database, providing a clean example of a CRUD-based web application.

---

## Features  

- User-friendly voting interface  
- Admin panel to manage polls & results  
- Real-time vote counting and display  
- Secure database storage with MySQL  
- Modular JSP pages with reusable header & footer  
- Responsive UI with Bootstrap

---

## Tech Stack  

- **Frontend:** JSP, HTML5, CSS3, Bootstrap  
- **Backend:** Java Servlets, JSP  
- **Database:** MySQL  
- **Server:** Apache Tomcat

---

## Project Structure  

VotingApp/
│── src/ # Java source files (Servlets, Database connection)
│── WebContent/ # JSP pages, CSS, JS, images
│ ├── index.jsp # Landing page
│ ├── categories.jsp # Poll categories
│ ├── results.jsp # Voting results
│ └── WEB-INF/ # web.xml configuration
│── sql/ # SQL scripts for DB setup
│── lib/ # Dependencies (MySQL Connector, etc.)
└── README.md # Project documentation


---

## Installation & Setup  

### 1. Clone the repository  
```bash
git clone https://github.com/iamvikash28/VotingApp.git
cd VotingApp
```

2. Import into IDE
- Open Eclipse / IntelliJ
- Select Import as Dynamic Web Project
- Configure Apache Tomcat as your server

3. Setup MySQL Database
- Create a new database:
```bash
CREATE DATABASE votingapp;
```

- Import tables from sql/votingapp.sql
- Update your DB credentials in DBConnection.java:
```bash
private static final String URL = "jdbc:mysql://localhost:3306/votingapp";
private static final String USER = "root";
private static final String PASSWORD = "your_password";
```

4. Run the Application

- Deploy on Tomcat server
- Open in browser:
```bash
http://localhost:8080/VotingApp
```

---

Usage

User:
- View categories of polls
- Cast votes
- See live results

Admin:
- Add new categories
- Manage polls
- View statistics

---
Future Enhancements

- User authentication & login system
- Graphical representation of results
- Multi-language support
- Mobile-friendly responsive UI

---
Contributing
- Fork the repo
- Create a new branch (feature/your-feature)
- Commit your changes
- Push to your branch
- Open a Pull Request

---

License

This project is licensed under the MIT License – feel free to use and modify.
