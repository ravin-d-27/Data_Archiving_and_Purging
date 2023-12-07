

<body>

  <h1>Data Archiving and Purging</h1>

  <p>This repository contains the SQL Scripts to perform Data Archiving and Purging along with Proper updates via Email using Microsoft SQL Server.</p>

<p><b>Note: </b>This is a Real Time project which I was working on for my internship as a Data Engineer Intern at <b>Sagitec Solutions</p>
</b>
  <h2>Basic Definitions</h2>
  <p><b>Data Archiving: </b>Data archiving is the process of moving data that is no longer actively used to a separate storage location for long-term retention. Archived data is typically retained for historical or compliance purposes.</p>
  <p><b>Data Purging: </b>Data purging is the process of permanently removing or deleting data that is no longer needed or has exceeded its retention period. Purging ensures that unnecessary data is removed from the system to free up storage space and improve system performance.</p>

  <h2>Features</h2>

  <ol>
    <li>
      <strong>Ready to use</strong>
      <ul>
        <li>The Scripts provided in my repository is completely reusable</li>
        <li>Just Change the parameters of the procedure according to your usecase, and it is ready to use</li>
      </ul>
    </li>
    <li>
      <strong>Completely Dynamic (No Manual Intervention)</strong>
      <ul>
        <li>The SQL Scripts provided is completely dynamic, so no need of any manual intervention.</li>
      </ul>
    </li>
    <li>
      <strong>Automatic column addition and missing column management</strong>
      <ul>
        <li>Whenever a new column is added in the source table, the same column will also be added in the target table also.</li>
        <li>If a column is removed from the source table, the script won't delete the column in the target table. Instead it preserves the previous data in the column</li>
      </ul>
    </li>
        <li>
      <strong>Email Notification after completing the Data Archival and Data Purging Operation</strong>
      <ul>
        <li>If the operation is completed, it notifies the user through the given Email ID along with some details of the operations such as Start Time, End Time, Source Table, Destination Table and so on</li>
      </ul>
    </li>
    <li>
      <strong>Maintains a Detailed Log Table</strong>
      <ul>
        <li>It also maintains a log table to have a track of the operations performed over time.</li>
        <li>The Log Table has most of the information with respect to the operation as well as information about the Tables and the Data (Primary Keys Moved) as well</li>
      </ul>
    </li>
  </ol>

  <h2>Tools Used</h2>

  <ul>
    <li>Microsoft SQL Server 2022</li>
    <li>Microsoft SSMS (SQL Server Management Studio 19)</li>
  </ul>


<h2>Acknowledgment</h2>

<ul>
  <li>This project owes its success to the invaluable assistance and direction provided by Mr. Venkateswaran, Manager at Sagitec Solutions.</li>
</ul>

</body>
