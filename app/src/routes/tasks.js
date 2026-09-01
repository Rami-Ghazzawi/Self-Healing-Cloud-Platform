const express = require("express");
const router = express.Router();

const { pool } = require("../db");

// GET /api/tasks
router.get("/", async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        id,
        title,
        description,
        completed,
        created_at,
        updated_at
      FROM tasks
      ORDER BY created_at DESC
    `);

    res.json(result.rows);
  } catch (error) {
    console.error("GET /api/tasks error:", error);

    res.status(500).json({
      error: "Failed to fetch tasks"
    });
  }
});

// GET /api/tasks/:id
router.get("/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      `
      SELECT
        id,
        title,
        description,
        completed,
        created_at,
        updated_at
      FROM tasks
      WHERE id = $1
      `,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: "Task not found"
      });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error("GET /api/tasks/:id error:", error);

    res.status(500).json({
      error: "Failed to fetch task"
    });
  }
});

// POST /api/tasks
router.post("/", async (req, res) => {
  try {
    const { title, description } = req.body;

    if (!title || !title.trim()) {
      return res.status(400).json({
        error: "Title is required"
      });
    }

    const result = await pool.query(
      `
      INSERT INTO tasks (title, description)
      VALUES ($1, $2)
      RETURNING *
      `,
      [title.trim(), description || null]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error("POST /api/tasks error:", error);

    res.status(500).json({
      error: "Failed to create task"
    });
  }
});

// PATCH /api/tasks/:id
router.patch("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, completed } = req.body;

    const existing = await pool.query(
      "SELECT * FROM tasks WHERE id = $1",
      [id]
    );

    if (existing.rows.length === 0) {
      return res.status(404).json({
        error: "Task not found"
      });
    }

    const currentTask = existing.rows[0];

    const updatedTitle =
      title !== undefined ? title.trim() : currentTask.title;

    const updatedDescription =
      description !== undefined
        ? description
        : currentTask.description;

    const updatedCompleted =
      completed !== undefined
        ? completed
        : currentTask.completed;

    if (!updatedTitle) {
      return res.status(400).json({
        error: "Title cannot be empty"
      });
    }

    const result = await pool.query(
      `
      UPDATE tasks
      SET
        title = $1,
        description = $2,
        completed = $3,
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $4
      RETURNING *
      `,
      [
        updatedTitle,
        updatedDescription,
        updatedCompleted,
        id
      ]
    );

    res.json(result.rows[0]);
  } catch (error) {
    console.error("PATCH /api/tasks/:id error:", error);

    res.status(500).json({
      error: "Failed to update task"
    });
  }
});

// DELETE /api/tasks/:id
router.delete("/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      `
      DELETE FROM tasks
      WHERE id = $1
      RETURNING *
      `,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: "Task not found"
      });
    }

    res.json({
      message: "Task deleted successfully",
      task: result.rows[0]
    });
  } catch (error) {
    console.error("DELETE /api/tasks/:id error:", error);

    res.status(500).json({
      error: "Failed to delete task"
    });
  }
});

module.exports = router;