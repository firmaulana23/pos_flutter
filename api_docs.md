# POS System Coffee Shop - API Documentation

## Base URL
```
http://localhost:8080/api/v1
```

## Authentication
Most endpoints require JWT authentication. Include the token in the Authorization header:
```
Authorization: Bearer <jwt_token>
```

---

## 1. Authentication Endpoints

### 1.1 User Registration
**POST** `/auth/register`

**Request Body:**
```json
{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "password123",
  "full_name": "John Doe",
  "role": "cashier"
}
```

**Response (201 Created):**
```json
{
  "message": "User registered successfully",
  "user": {
    "id": 1,
    "username": "john_doe",
    "email": "john@example.com",
    "full_name": "John Doe",
    "role": "cashier",
    "created_at": "2025-07-07T12:00:00Z",
    "updated_at": "2025-07-07T12:00:00Z"
  }
}
```

**Response (400 Bad Request):**
```json
{
  "error": "Username already exists"
}
```

### 1.2 User Login
**POST** `/auth/login`

**Request Body:**
```json
{
  "username": "john_doe",
  "password": "password123"
}
```

**Response (200 OK):**
```json
{
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "username": "john_doe",
    "email": "john@example.com",
    "full_name": "John Doe",
    "role": "cashier"
  }
}
```

**Response (401 Unauthorized):**
```json
{
  "error": "Invalid credentials"
}
```

---

## 2. User Management Endpoints

### 2.1 Get All Users
**GET** `/users`
*Requires: Admin or Manager role*

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "username": "admin",
    "email": "admin@pos.com",
    "full_name": "Administrator",
    "role": "admin",
    "created_at": "2025-07-07T12:00:00Z",
    "updated_at": "2025-07-07T12:00:00Z"
  },
  {
    "id": 2,
    "username": "cashier1",
    "email": "cashier@pos.com",
    "full_name": "Cashier One",
    "role": "cashier",
    "created_at": "2025-07-07T12:00:00Z",
    "updated_at": "2025-07-07T12:00:00Z"
  }
]
```

### 2.2 Get User by ID
**GET** `/users/{id}`
*Requires: Authentication*

**Response (200 OK):**
```json
{
  "id": 1,
  "username": "john_doe",
  "email": "john@example.com",
  "full_name": "John Doe",
  "role": "cashier",
  "created_at": "2025-07-07T12:00:00Z",
  "updated_at": "2025-07-07T12:00:00Z"
}
```

### 2.3 Update User
**PUT** `/users/{id}`
*Requires: Admin or Manager role*

**Request Body:**
```json
{
  "username": "john_updated",
  "email": "john.updated@example.com",
  "full_name": "John Doe Updated",
  "role": "manager"
}
```

**Response (200 OK):**
```json
{
  "message": "User updated successfully",
  "user": {
    "id": 1,
    "username": "john_updated",
    "email": "john.updated@example.com",
    "full_name": "John Doe Updated",
    "role": "manager",
    "created_at": "2025-07-07T12:00:00Z",
    "updated_at": "2025-07-07T12:00:01Z"
  }
}
```

### 2.4 Delete User
**DELETE** `/users/{id}`
*Requires: Admin role*

**Response (200 OK):**
```json
{
  "message": "User deleted successfully"
}
```

---

## 3. Category Endpoints

### 3.1 Get All Categories
**GET** `/public/categories` or `/categories`

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "name": "Coffee",
    "description": "Hot and cold coffee beverages",
    "created_at": "2025-07-07T12:00:00Z",
    "updated_at": "2025-07-07T12:00:00Z"
  },
  {
    "id": 2,
    "name": "Tea",
    "description": "Various tea selections",
    "created_at": "2025-07-07T12:00:00Z",
    "updated_at": "2025-07-07T12:00:00Z"
  }
]
```

### 3.2 Create Category
**POST** `/categories`
*Requires: Admin or Manager role*

**Request Body:**
```json
{
  "name": "Pastries",
  "description": "Fresh baked goods and pastries"
}
```

**Response (201 Created):**
```json
{
  "id": 3,
  "name": "Pastries",
  "description": "Fresh baked goods and pastries",
  "created_at": "2025-07-07T12:00:00Z",
  "updated_at": "2025-07-07T12:00:00Z"
}
```

### 3.3 Update Category
**PUT** `/categories/{id}`
*Requires: Admin or Manager role*

**Request Body:**
```json
{
  "name": "Baked Goods",
  "description": "Fresh baked pastries and breads"
}
```

**Response (200 OK):**
```json
{
  "id": 3,
  "name": "Baked Goods",
  "description": "Fresh baked pastries and breads",
  "created_at": "2025-07-07T12:00:00Z",
  "updated_at": "2025-07-07T12:00:01Z"
}
```

### 3.4 Delete Category
**DELETE** `/categories/{id}`
*Requires: Admin or Manager role*

**Response (200 OK):**
```json
{
  "message": "Category deleted successfully"
}
```

---

## 4. Menu Item Endpoints

### 4.1 Get All Menu Items
**GET** `/public/menu/items` or `/menu/items`

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 10)
- `category_id` (optional): Filter by category ID

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": 1,
      "name": "Espresso",
      "description": "Rich and bold espresso shot",
      "category_id": 1,
      "category": {
        "id": 1,
        "name": "Coffee",
        "description": "Hot and cold coffee beverages"
      },
      "price": 25000,
      "cogs": 8000,
      "margin": 68.0,
      "image_url": "",
      "available": true,
      "created_at": "2025-07-07T12:00:00Z",
      "updated_at": "2025-07-07T12:00:00Z"
    }
  ],
  "page": 1,
  "limit": 10,
  "total": 1
}
```

### 4.2 Get Menu Item by ID
**GET** `/menu/items/{id}`

**Response (200 OK):**
```json
{
  "id": 1,
  "name": "Espresso",
  "description": "Rich and bold espresso shot",
  "category_id": 1,
  "category": {
    "id": 1,
    "name": "Coffee",
    "description": "Hot and cold coffee beverages"
  },
  "price": 25000,
  "cogs": 8000,
  "margin": 68.0,
  "image_url": "",
  "available": true,
  "created_at": "2025-07-07T12:00:00Z",
  "updated_at": "2025-07-07T12:00:00Z"
}
```

### 4.3 Create Menu Item
**POST** `/menu/items`
*Requires: Admin or Manager role*

**Request Body:**
```json
{
  "name": "Cappuccino",
  "description": "Espresso with steamed milk and foam",
  "category_id": 1,
  "price": 35000,
  "cogs": 12000,
  "image_url": "",
  "available": true
}
```

**Response (201 Created):**
```json
{
  "id": 2,
  "name": "Cappuccino",
  "description": "Espresso with steamed milk and foam",
  "category_id": 1,
  "category": {
    "id": 1,
    "name": "Coffee",
    "description": "Hot and cold coffee beverages"
  },
  "price": 35000,
  "cogs": 12000,
  "margin": 65.71,
  "image_url": "",
  "available": true,
  "created_at": "2025-07-07T12:00:00Z",
  "updated_at": "2025-07-07T12:00:00Z"
}
```

### 4.4 Update Menu Item
**PUT** `/menu/items/{id}`
*Requires: Admin or Manager role*

**Request Body:**
```json
{
  "name": "Large Cappuccino",
  "description": "Double shot espresso with steamed milk and foam",
  "category_id": 1,
  "price": 45000,
  "cogs": 15000,
  "image_url": "",
  "available": true
}
```

**Response (200 OK):**
```json
{
  "id": 2,
  "name": "Large Cappuccino",
  "description": "Double shot espresso with steamed milk and foam",
  "category_id": 1,
  "category": {
    "id": 1,
    "name": "Coffee",
    "description": "Hot and cold coffee beverages"
  },
  "price": 45000,
  "cogs": 15000,
  "margin": 66.67,
  "image_url": "",
  "available": true,
  "created_at": "2025-07-07T12:00:00Z",
  "updated_at": "2025-07-07T12:00:01Z"
}
```

### 4.5 Delete Menu Item
**DELETE** `/menu/items/{id}`
*Requires: Admin or Manager role*

**Response (200 OK):**
```json
{
  "message": "Menu item deleted successfully"
}
```

---

## 5. Add-on Endpoints

### 5.1 Get All Add-ons
**GET** `/public/add-ons` or `/add-ons`

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "name": "Extra Shot",
    "description": "Additional espresso shot",
    "price": 8000,
    "cogs": 2000,
    "margin": 75.0,
    "available": true,
    "created_at": "2025-07-07T12:00:00Z",
    "updated_at": "2025-07-07T12:00:00Z"
  },
  {
    "id": 2,
    "name": "Oat Milk",
    "description": "Replace regular milk with oat milk",
    "price": 5000,
    "cogs": 2500,
    "margin": 50.0,
    "available": true,
    "created_at": "2025-07-07T12:00:00Z",
    "updated_at": "2025-07-07T12:00:00Z"
  }
]
```

### 5.2 Create Add-on
**POST** `/add-ons`
*Requires: Admin or Manager role*

**Request Body:**
```json
{
  "name": "Almond Milk",
  "description": "Replace regular milk with almond milk",
  "price": 6000,
  "cogs": 3000,
  "available": true
}
```

**Response (201 Created):**
```json
{
  "id": 3,
  "name": "Almond Milk",
  "description": "Replace regular milk with almond milk",
  "price": 6000,
  "cogs": 3000,
  "margin": 50.0,
  "available": true,
  "created_at": "2025-07-07T12:00:00Z",
  "updated_at": "2025-07-07T12:00:00Z"
}
```

### 5.3 Update Add-on
**PUT** `/add-ons/{id}`
*Requires: Admin or Manager role*

**Request Body:**
```json
{
  "name": "Premium Almond Milk",
  "description": "Organic almond milk substitute",
  "price": 7000,
  "cogs": 3500,
  "available": true
}
```

**Response (200 OK):**
```json
{
  "id": 3,
  "name": "Premium Almond Milk",
  "description": "Organic almond milk substitute",
  "price": 7000,
  "cogs": 3500,
  "margin": 50.0,
  "available": true,
  "created_at": "2025-07-07T12:00:00Z",
  "updated_at": "2025-07-07T12:00:01Z"
}
```

### 5.4 Delete Add-on
**DELETE** `/add-ons/{id}`
*Requires: Admin or Manager role*

**Response (200 OK):**
```json
{
  "message": "Add-on deleted successfully"
}
```

---

## 6. Transaction Endpoints

### 6.1 Get All Transactions
**GET** `/transactions`
*Requires: Authentication*

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 10)
- `status` (optional): Filter by status ("pending" or "paid")
- `start_date` (optional): Start date filter (YYYY-MM-DD)
- `end_date` (optional): End date filter (YYYY-MM-DD)

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": 1,
      "user_id": 2,
      "user": {
        "id": 2,
        "username": "cashier1",
        "full_name": "Cashier One"
      },
      "status": "paid",
      "payment_method": {
        "id": 1,
        "name": "Cash",
        "code": "cash"
      },
      "total_amount": 43000,
      "tax_amount": 4300,
      "discount_amount": 0,
      "final_amount": 47300,
      "notes": "",
      "transaction_items": [
        {
          "id": 1,
          "menu_item": {
            "id": 1,
            "name": "Espresso",
            "price": 25000
          },
          "quantity": 1,
          "price": 25000,
          "total": 25000,
          "add_ons": [
            {
              "id": 1,
              "add_on": {
                "id": 1,
                "name": "Extra Shot",
                "price": 8000
              },
              "quantity": 1,
              "price": 8000,
              "total": 8000
            }
          ]
        }
      ],
      "created_at": "2025-07-07T12:00:00Z",
      "updated_at": "2025-07-07T12:00:00Z"
    }
  ],
  "page": 1,
  "limit": 10,
  "total": 1
}
```

### 6.2 Get Transaction by ID
**GET** `/transactions/{id}`
*Requires: Authentication*

**Response (200 OK):**
```json
{
  "id": 1,
  "user_id": 2,
  "user": {
    "id": 2,
    "username": "cashier1",
    "full_name": "Cashier One"
  },
  "status": "paid",
  "payment_method": {
    "id": 1,
    "name": "Cash",
    "code": "cash"
  },
  "total_amount": 43000,
  "tax_amount": 4300,
  "discount_amount": 0,
  "final_amount": 47300,
  "notes": "",
  "transaction_items": [
    {
      "id": 1,
      "menu_item": {
        "id": 1,
        "name": "Espresso",
        "price": 25000
      },
      "quantity": 1,
      "price": 25000,
      "total": 25000,
      "add_ons": [
        {
          "id": 1,
          "add_on": {
            "id": 1,
            "name": "Extra Shot",
            "price": 8000
          },
          "quantity": 1,
          "price": 8000,
          "total": 8000
        }
      ]
    }
  ],
  "created_at": "2025-07-07T12:00:00Z",
  "updated_at": "2025-07-07T12:00:00Z"
}
```

### 6.3 Create Transaction (Save as Pending)
**POST** `/transactions`
*Requires: Authentication*

**Request Body:**
```json
{
  "items": [
    {
      "menu_item_id": 1,
      "quantity": 2,
      "add_ons": [
        {
          "add_on_id": 1,
          "quantity": 1
        }
      ]
    },
    {
      "menu_item_id": 2,
      "quantity": 1,
      "add_ons": []
    }
  ],
  "discount_amount": 5000,
  "notes": "Customer request: less sugar"
}
```

**Response (201 Created):**
```json
{
  "id": 2,
  "user_id": 2,
  "status": "pending",
  "payment_method": null,
  "total_amount": 85000,
  "tax_amount": 8500,
  "discount_amount": 5000,
  "final_amount": 88500,
  "notes": "Customer request: less sugar",
  "transaction_items": [
    {
      "id": 2,
      "menu_item": {
        "id": 1,
        "name": "Espresso",
        "price": 25000
      },
      "quantity": 2,
      "price": 25000,
      "total": 50000,
      "add_ons": [
        {
          "id": 2,
          "add_on": {
            "id": 1,
            "name": "Extra Shot",
            "price": 8000
          },
          "quantity": 1,
          "price": 8000,
          "total": 8000
        }
      ]
    }
  ],
  "created_at": "2025-07-07T12:00:00Z",
  "updated_at": "2025-07-07T12:00:00Z"
}
```

### 6.4 Pay Transaction (Create and Pay Immediately)
**POST** `/transactions/pay`
*Requires: Authentication*

**Request Body:**
```json
{
  "items": [
    {
      "menu_item_id": 1,
      "quantity": 1,
      "add_ons": [
        {
          "add_on_id": 1,
          "quantity": 1
        }
      ]
    }
  ],
  "payment_method": "cash",
  "discount_amount": 0,
  "notes": ""
}
```

**Response (201 Created):**
```json
{
  "id": 3,
  "user_id": 2,
  "status": "paid",
  "payment_method": {
    "id": 1,
    "name": "Cash",
    "code": "cash"
  },
  "total_amount": 33000,
  "tax_amount": 3300,
  "discount_amount": 0,
  "final_amount": 36300,
  "notes": "",
  "transaction_items": [
    {
      "id": 3,
      "menu_item": {
        "id": 1,
        "name": "Espresso",
        "price": 25000
      },
      "quantity": 1,
      "price": 25000,
      "total": 25000,
      "add_ons": [
        {
          "id": 3,
          "add_on": {
            "id": 1,
            "name": "Extra Shot",
            "price": 8000
          },
          "quantity": 1,
          "price": 8000,
          "total": 8000
        }
      ]
    }
  ],
  "created_at": "2025-07-07T12:00:00Z",
  "updated_at": "2025-07-07T12:00:00Z"
}
```

### 6.5 Mark Transaction as Paid
**PUT** `/transactions/{id}/pay`
*Requires: Authentication*

**Request Body:**
```json
{
  "payment_method": "card"
}
```

**Response (200 OK):**
```json
{
  "message": "Transaction marked as paid successfully",
  "transaction": {
    "id": 2,
    "user_id": 2,
    "status": "paid",
    "payment_method": {
      "id": 2,
      "name": "Credit Card",
      "code": "card"
    },
    "total_amount": 85000,
    "tax_amount": 8500,
    "discount_amount": 5000,
    "final_amount": 88500,
    "notes": "Customer request: less sugar",
    "updated_at": "2025-07-07T12:00:01Z"
  }
}
```

---

## 7. Payment Method Endpoints

### 7.1 Get All Payment Methods
**GET** `/public/payment-methods` or `/payment-methods`

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "name": "Cash",
    "code": "cash",
    "active": true,
    "created_at": "2025-07-07T12:00:00Z",
    "updated_at": "2025-07-07T12:00:00Z"
  },
  {
    "id": 2,
    "name": "Credit Card",
    "code": "card",
    "active": true,
    "created_at": "2025-07-07T12:00:00Z",
    "updated_at": "2025-07-07T12:00:00Z"
  },
  {
    "id": 3,
    "name": "Digital Wallet",
    "code": "digital_wallet",
    "active": true,
    "created_at": "2025-07-07T12:00:00Z",
    "updated_at": "2025-07-07T12:00:00Z"
  }
]
```

---

## 8. Expense Endpoints

### 8.1 Get All Expenses
**GET** `/expenses`
*Requires: Admin or Manager role*

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 10)
- `type` (optional): Filter by type ("raw_material" or "operational")
- `start_date` (optional): Start date filter (YYYY-MM-DD)
- `end_date` (optional): End date filter (YYYY-MM-DD)

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": 1,
      "type": "raw_material",
      "category": "Coffee Beans",
      "description": "Premium Arabica coffee beans - 5kg",
      "amount": 250000,
      "date": "2025-07-07",
      "receipt_number": "RCP-001",
      "supplier": "Local Coffee Supplier",
      "notes": "High quality beans for espresso",
      "created_at": "2025-07-07T12:00:00Z",
      "updated_at": "2025-07-07T12:00:00Z"
    },
    {
      "id": 2,
      "type": "operational",
      "category": "Utilities",
      "description": "Monthly electricity bill",
      "amount": 150000,
      "date": "2025-07-01",
      "receipt_number": "ELC-202507",
      "supplier": "PLN",
      "notes": "July 2025 electricity",
      "created_at": "2025-07-07T12:00:00Z",
      "updated_at": "2025-07-07T12:00:00Z"
    }
  ],
  "page": 1,
  "limit": 10,
  "total": 2
}
```

### 8.2 Create Expense
**POST** `/expenses`
*Requires: Admin or Manager role*

**Request Body:**
```json
{
  "type": "raw_material",
  "category": "Milk",
  "description": "Fresh milk for beverages - 20L",
  "amount": 80000,
  "date": "2025-07-07",
  "receipt_number": "MLK-001",
  "supplier": "Dairy Farm Co.",
  "notes": "Weekly milk supply"
}
```

**Response (201 Created):**
```json
{
  "id": 3,
  "type": "raw_material",
  "category": "Milk",
  "description": "Fresh milk for beverages - 20L",
  "amount": 80000,
  "date": "2025-07-07",
  "receipt_number": "MLK-001",
  "supplier": "Dairy Farm Co.",
  "notes": "Weekly milk supply",
  "created_at": "2025-07-07T12:00:00Z",
  "updated_at": "2025-07-07T12:00:00Z"
}
```

### 8.3 Update Expense
**PUT** `/expenses/{id}`
*Requires: Admin or Manager role*

**Request Body:**
```json
{
  "type": "raw_material",
  "category": "Milk",
  "description": "Fresh organic milk for beverages - 20L",
  "amount": 95000,
  "date": "2025-07-07",
  "receipt_number": "MLK-001-REV",
  "supplier": "Organic Dairy Farm Co.",
  "notes": "Weekly organic milk supply"
}
```

**Response (200 OK):**
```json
{
  "id": 3,
  "type": "raw_material",
  "category": "Milk",
  "description": "Fresh organic milk for beverages - 20L",
  "amount": 95000,
  "date": "2025-07-07",
  "receipt_number": "MLK-001-REV",
  "supplier": "Organic Dairy Farm Co.",
  "notes": "Weekly organic milk supply",
  "created_at": "2025-07-07T12:00:00Z",
  "updated_at": "2025-07-07T12:00:01Z"
}
```

### 8.4 Delete Expense
**DELETE** `/expenses/{id}`
*Requires: Admin or Manager role*

**Response (200 OK):**
```json
{
  "message": "Expense deleted successfully"
}
```

---

## 9. Dashboard Analytics Endpoints

### 9.1 Get Dashboard Statistics
**GET** `/dashboard/stats`
*Requires: Authentication*

**Query Parameters:**
- `start_date` (optional): Start date filter (YYYY-MM-DD)
- `end_date` (optional): End date filter (YYYY-MM-DD)

**Response (200 OK):**
```json
{
  "today_sales": 450000,
  "today_transactions": 25,
  "avg_order_value": 18000,
  "total_expenses": 180000,
  "sales_growth": 15.5,
  "transaction_growth": 8,
  "avg_order_growth": 12.3,
  "top_menu_items": [
    {
      "name": "Espresso",
      "total_quantity": 45,
      "total_revenue": 1125000
    },
    {
      "name": "Cappuccino",
      "total_quantity": 32,
      "total_revenue": 1120000
    }
  ],
  "top_add_ons": [
    {
      "name": "Extra Shot",
      "total_quantity": 28,
      "total_revenue": 224000
    },
    {
      "name": "Oat Milk",
      "total_quantity": 15,
      "total_revenue": 75000
    }
  ],
  "sales_chart_data": [
    {
      "date": "2025-07-01",
      "sales": 380000,
      "transactions": 21
    },
    {
      "date": "2025-07-02",
      "sales": 420000,
      "transactions": 24
    }
  ],
  "expense_chart_data": [
    {
      "date": "2025-07-01",
      "raw_material": 150000,
      "operational": 80000
    },
    {
      "date": "2025-07-02",
      "raw_material": 120000,
      "operational": 75000
    }
  ]
}
```

---

## 10. Health Check Endpoint

### 10.1 Health Check
**GET** `/health`

**Response (200 OK):**
```json
{
  "status": "ok",
  "timestamp": "2025-07-07T12:00:00Z",
  "version": "1.0.0",
  "database": "connected"
}
```

---

## Error Responses

### Common Error Formats

**400 Bad Request:**
```json
{
  "error": "Invalid request format",
  "details": "Missing required field: name"
}
```

**401 Unauthorized:**
```json
{
  "error": "Authentication required"
}
```

**403 Forbidden:**
```json
{
  "error": "Insufficient permissions",
  "required_role": "admin"
}
```

**404 Not Found:**
```json
{
  "error": "Resource not found",
  "resource": "menu_item",
  "id": 999
}
```

**422 Unprocessable Entity:**
```json
{
  "error": "Validation failed",
  "fields": {
    "email": "Invalid email format",
    "password": "Password must be at least 6 characters"
  }
}
```

**500 Internal Server Error:**
```json
{
  "error": "Internal server error",
  "message": "Something went wrong"
}
```

---

## cURL Examples

Below are practical cURL command examples for testing all API endpoints:

### Authentication Examples

#### Register a new user
```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123",
    "full_name": "Test User",
    "role": "cashier"
  }'
```

#### Login
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123"
  }'
```

*Save the token from login response for subsequent requests*

### User Management Examples

#### Get all users (Admin/Manager only)
```bash
curl -X GET http://localhost:8080/api/v1/users \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

#### Get user by ID
```bash
curl -X GET http://localhost:8080/api/v1/users/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

#### Update user (Admin/Manager only)
```bash
curl -X PUT http://localhost:8080/api/v1/users/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "updated_user",
    "email": "updated@example.com",
    "full_name": "Updated User",
    "role": "manager"
  }'
```

#### Delete user (Admin only)
```bash
curl -X DELETE http://localhost:8080/api/v1/users/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Category Examples

#### Get all categories (Public)
```bash
curl -X GET http://localhost:8080/api/v1/public/menu/categories
```

#### Create category (Admin/Manager only)
```bash
curl -X POST http://localhost:8080/api/v1/menu/categories \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Beverages",
    "description": "Hot and cold beverages"
  }'
```

#### Update category (Admin/Manager only)
```bash
curl -X PUT http://localhost:8080/api/v1/categories/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Hot Beverages",
    "description": "Hot coffee and tea selections"
  }'
```

#### Delete category (Admin/Manager only)
```bash
curl -X DELETE http://localhost:8080/api/v1/categories/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Menu Item Examples

#### Get all menu items (Public)
```bash
curl -X GET http://localhost:8080/api/v1/public/menu/items
```

#### Get menu items with pagination and filters
```bash
curl -X GET "http://localhost:8080/api/v1/public/menu/items?page=1&limit=5&category_id=1"
```

#### Get menu item by ID
```bash
curl -X GET http://localhost:8080/api/v1/menu/items/1
```

#### Create menu item (Admin/Manager only)
```bash
curl -X POST http://localhost:8080/api/v1/menu/items \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Americano",
    "description": "Espresso with hot water",
    "category_id": 1,
    "price": 30000,
    "cogs": 10000,
    "image_url": "",
    "available": true
  }'
```

#### Update menu item (Admin/Manager only)
```bash
curl -X PUT http://localhost:8080/api/v1/menu/items/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Large Americano",
    "description": "Double shot espresso with hot water",
    "category_id": 1,
    "price": 40000,
    "cogs": 15000,
    "image_url": "",
    "available": true
  }'
```

#### Delete menu item (Admin/Manager only)
```bash
curl -X DELETE http://localhost:8080/api/v1/menu/items/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Add-on Examples

#### Get all add-ons (Public)
```bash
curl -X GET http://localhost:8080/api/v1/public/add-ons
```

#### Create add-on (Admin/Manager only)
```bash
curl -X POST http://localhost:8080/api/v1/add-ons \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Vanilla Syrup",
    "description": "Sweet vanilla flavoring",
    "price": 5000,
    "cogs": 1500,
    "available": true
  }'
```

#### Update add-on (Admin/Manager only)
```bash
curl -X PUT http://localhost:8080/api/v1/add-ons/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Premium Vanilla Syrup",
    "description": "High-quality vanilla flavoring",
    "price": 6000,
    "cogs": 2000,
    "available": true
  }'
```

#### Delete add-on (Admin/Manager only)
```bash
curl -X DELETE http://localhost:8080/api/v1/add-ons/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Transaction Examples

#### Get all transactions
```bash
curl -X GET http://localhost:8080/api/v1/transactions \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

#### Get transactions with filters
```bash
curl -X GET "http://localhost:8080/api/v1/transactions?status=paid&start_date=2025-07-01&end_date=2025-07-07&page=1&limit=10" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

#### Get transaction by ID
```bash
curl -X GET http://localhost:8080/api/v1/transactions/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

#### Create transaction (save as pending)
```bash
curl -X POST http://localhost:8080/api/v1/transactions \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {
        "menu_item_id": 1,
        "quantity": 2,
        "add_ons": [
          {
            "add_on_id": 1,
            "quantity": 1
          }
        ]
      },
      {
        "menu_item_id": 2,
        "quantity": 1,
        "add_ons": []
      }
    ],
    "discount_amount": 5000,
    "notes": "Customer special request"
  }'
```

#### Create and pay transaction immediately
```bash
curl -X POST http://localhost:8080/api/v1/transactions/pay \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {
        "menu_item_id": 1,
        "quantity": 1,
        "add_ons": [
          {
            "add_on_id": 1,
            "quantity": 1
          }
        ]
      }
    ],
    "payment_method": "cash",
    "discount_amount": 0,
    "notes": ""
  }'
```

#### Mark existing transaction as paid
```bash
curl -X PUT http://localhost:8080/api/v1/transactions/1/pay \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "payment_method": "card"
  }'
```

### Payment Method Examples

#### Get all payment methods (Public)
```bash
curl -X GET http://localhost:8080/api/v1/public/payment-methods
```

### Expense Examples

#### Get all expenses (Admin/Manager only)
```bash
curl -X GET http://localhost:8080/api/v1/expenses \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

#### Get expenses with filters
```bash
curl -X GET "http://localhost:8080/api/v1/expenses?type=raw_material&start_date=2025-07-01&end_date=2025-07-07&page=1&limit=10" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

#### Create expense (Admin/Manager only)
```bash
curl -X POST http://localhost:8080/api/v1/expenses \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "raw_material",
    "category": "Coffee Beans",
    "description": "Premium Colombian beans - 2kg",
    "amount": 180000,
    "date": "2025-07-07",
    "receipt_number": "CB-001",
    "supplier": "Coffee Import Co.",
    "notes": "For espresso blend"
  }'
```

#### Update expense (Admin/Manager only)
```bash
curl -X PUT http://localhost:8080/api/v1/expenses/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "raw_material",
    "category": "Coffee Beans",
    "description": "Premium Colombian beans - 2.5kg",
    "amount": 200000,
    "date": "2025-07-07",
    "receipt_number": "CB-001-REV",
    "supplier": "Coffee Import Co.",
    "notes": "Updated quantity for espresso blend"
  }'
```

#### Delete expense (Admin/Manager only)
```bash
curl -X DELETE http://localhost:8080/api/v1/expenses/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Dashboard Examples

#### Get dashboard statistics
```bash
curl -X GET http://localhost:8080/api/v1/dashboard/stats \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

#### Get dashboard statistics with date filter
```bash
curl -X GET "http://localhost:8080/api/v1/dashboard/stats?start_date=2025-07-01&end_date=2025-07-07" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Health Check

#### Check API health
```bash
curl -X GET http://localhost:8080/api/v1/health
```

---

## Complete Workflow Examples

### 1. Complete User Registration and Login Flow
```bash
# 1. Register a new user
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "cashier_demo",
    "email": "cashier@demo.com",
    "password": "demo123",
    "full_name": "Demo Cashier",
    "role": "cashier"
  }'

# 2. Login to get JWT token
TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "cashier_demo",
    "password": "demo123"
  }' | jq -r '.token')

echo "Token: $TOKEN"
```

### 2. Complete Menu Setup Flow
```bash
# Assuming you have admin token
ADMIN_TOKEN="your_admin_jwt_token"

# 1. Create category
CATEGORY_ID=$(curl -s -X POST http://localhost:8080/api/v1/categories \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Coffee",
    "description": "Coffee beverages"
  }' | jq -r '.id')

# 2. Create menu item
ITEM_ID=$(curl -s -X POST http://localhost:8080/api/v1/menu/items \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Latte",
    "description": "Espresso with steamed milk",
    "category_id": '$CATEGORY_ID',
    "price": 40000,
    "cogs": 15000,
    "available": true
  }' | jq -r '.id')

# 3. Create add-on
ADDON_ID=$(curl -s -X POST http://localhost:8080/api/v1/add-ons \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Extra Shot",
    "description": "Additional espresso shot",
    "price": 8000,
    "cogs": 2500,
    "available": true
  }' | jq -r '.id')

echo "Created Category ID: $CATEGORY_ID, Item ID: $ITEM_ID, Add-on ID: $ADDON_ID"
```

### 3. Complete Transaction Flow
```bash
# Using cashier token
CASHIER_TOKEN="your_cashier_jwt_token"

# 1. Create pending transaction
TRANSACTION_ID=$(curl -s -X POST http://localhost:8080/api/v1/transactions \
  -H "Authorization: Bearer $CASHIER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {
        "menu_item_id": 1,
        "quantity": 2,
        "add_ons": [
          {
            "add_on_id": 1,
            "quantity": 1
          }
        ]
      }
    ],
    "discount_amount": 0,
    "notes": "Test order"
  }' | jq -r '.id')

# 2. Mark transaction as paid
curl -X PUT http://localhost:8080/api/v1/transactions/$TRANSACTION_ID/pay \
  -H "Authorization: Bearer $CASHIER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "payment_method": "cash"
  }'

echo "Created and paid Transaction ID: $TRANSACTION_ID"
```

### 4. Direct Payment Flow (Create and Pay Immediately)
```bash
# Create and pay transaction in one step
curl -X POST http://localhost:8080/api/v1/transactions/pay \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {
        "menu_item_id": 1,
        "quantity": 1,
        "add_ons": []
      }
    ],
    "payment_method": "card",
    "discount_amount": 5000,
    "notes": "Quick sale"
  }'
```

---

## Testing Tips

1. **Save JWT Token**: After login, save the token to a variable for easier testing:
   ```bash
   TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
     -H "Content-Type: application/json" \
     -d '{"username":"admin","password":"admin123"}' | jq -r '.token')
   ```

2. **Use Pretty JSON**: Add `| jq` to format JSON responses:
   ```bash
   curl -X GET http://localhost:8080/api/v1/users \
     -H "Authorization: Bearer $TOKEN" | jq
   ```

3. **Check HTTP Status**: Add `-w "%{http_code}"` to see response status:
   ```bash
   curl -w "%{http_code}" -X GET http://localhost:8080/api/v1/health
   ```

4. **Verbose Output**: Use `-v` flag for detailed request/response info:
   ```bash
   curl -v -X GET http://localhost:8080/api/v1/health
   ```

5. **Save Response**: Save response to file for inspection:
   ```bash
   curl -X GET http://localhost:8080/api/v1/transactions \
     -H "Authorization: Bearer $TOKEN" -o transactions.json
   ```

---