const express = require("express");
const path = require("path");
const { pool, testConnection, initializeDatabase } = require("./db");

const app = express();
const PORT = process.env.PORT || 8080;

app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));

// --- ALB Health Check ---
app.get("/health", async (req, res) => {
  try {
    await pool.query("SELECT 1");
    res.status(200).send("OK");
  } catch (err) {
    res.status(500).send("Unhealthy");
  }
});

// --- Tasks REST API Endpoints ---

// 1. GET /api/tasks - Fetch all tasks
app.get("/api/tasks", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM tasks ORDER BY created_at DESC");
    // Map database snake_case columns to frontend camelCase
    const tasks = result.rows.map(row => ({
      id: row.id.toString(),
      title: row.title,
      description: row.description || "",
      dueDate: row.due_date ? row.due_date.toISOString().slice(0, 10) : "",
      category: row.category || "Personal",
      priority: row.priority || "medium",
      completed: row.completed,
      createdAt: new Date(row.created_at).getTime()
    }));
    res.json(tasks);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to fetch tasks" });
  }
});

// 2. POST /api/tasks - Create a task
app.post("/api/tasks", async (req, res) => {
  const { title, description, dueDate, category, priority } = req.body;
  try {
    const result = await pool.query(
      `INSERT INTO tasks (title, description, due_date, category, priority)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [title, description, dueDate || null, category || "Personal", priority || "medium"]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to create task" });
  }
});

// 3. PUT /api/tasks/:id - Update or toggle task
app.put("/api/tasks/:id", async (req, res) => {
  const { id } = req.params;
  const { title, description, dueDate, category, priority, completed } = req.body;
  try {
    const result = await pool.query(
      `UPDATE tasks 
       SET title = COALESCE($1, title),
           description = COALESCE($2, description),
           due_date = COALESCE($3, due_date),
           category = COALESCE($4, category),
           priority = COALESCE($5, priority),
           completed = COALESCE($6, completed),
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $7 RETURNING *`,
      [title, description, dueDate, category, priority, completed, id]
    );
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to update task" });
  }
});

// 4. DELETE /api/tasks/:id - Delete a task
app.delete("/api/tasks/:id", async (req, res) => {
  const { id } = req.params;
  try {
    await pool.query("DELETE FROM tasks WHERE id = $1", [id]);
    res.status(204).send();
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to delete task" });
  }
});

// --- Server Initialization ---
async function start() {
  try {
    await testConnection();
    await initializeDatabase();
    app.listen(PORT, () => console.log(`Server listening on port ${PORT}`));
  } catch (err) {
    console.error("Failed to start server:", err);
    process.exit(1);
  }
}

start();