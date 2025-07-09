# POS System API Documentation

## Base URL
```
http://localhost:8080/api/v1
```

## Key Features

### Menu-Dependent Add-ons
The POS system supports two types of add-ons:

1. **Global Add-ons** (`menu_item_id: null`): Available for all menu items
   - Example: "Whipped Cream", "Extra Hot", "Decaf"
   
2. **Menu-Specific Add-ons** (`menu_item_id: 4`): Only available for specific menu items
   - Example: "Latte Art" (only for Lattes), "Extra Foam" (only for Cappuccinos)

This allows for better organization and more relevant add-on options for customers.

### New Endpoints for Menu-Dependent Add-ons:
- `GET /api/v1/public/menu-item-add-ons/{menu_item_id}` - Get add-ons for specific menu item
- `GET /api/v1/add-ons?menu_item_id=4` - Filter add-ons by menu item
- `GET /api/v1/add-ons?menu_item_id=global` - Get only global add-ons

## Authentication

The API uses JWT Bearer tokens for authentication. Include the token in the Authorization header:
```
Authorization: Bearer <jwt_token>
```

### Login
```http
POST /api/v1/auth/login
Content-Type: application/json

{
    "email": "admin@pos.com",
    "password": "admin123"
}
```

**Response:**
```json
{
    "success": true,
    "message": "Login successful",
    "data": {
        "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        "user": {
            "id": 1,
            "username": "admin",
            "email": "admin@pos.com",
            "role": "admin",
            "is_active": true
        }
    }
}
```

## User Management

### Get Profile
```http
GET /api/v1/profile
Authorization: Bearer <token>
```

### Register User (Admin only)
```http
POST /api/v1/auth/register
Authorization: Bearer <admin_token>
Content-Type: application/json

{
    "username": "newuser",
    "email": "newuser@pos.com",
    "password": "password123",
    "role": "cashier"
}
```

## Menu Management

### Get Categories
```http
GET /api/v1/menu/categories
```

**Response:**
```json
{
    "success": true,
    "data": [
        {
            "id": 1,
            "name": "Coffee",
            "description": "Hot and cold coffee beverages",
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z"
        }
    ]
}
```

### Create Category (Admin/Manager)
```http
POST /api/v1/menu/categories
Authorization: Bearer <token>
Content-Type: application/json

{
    "name": "New Category",
    "description": "Category description"
}
```

### Get Menu Items
```http
GET /api/v1/menu/items?category_id=1&available=true
```

**Response:**
```json
{
    "success": true,
    "data": [
        {
            "id": 4,
            "category_id": 1,
            "name": "Latte",
            "description": "Espresso with steamed milk",
            "price": 28000,
            "cogs": 14000,
            "margin": 50.0,
            "is_available": true,
            "image_url": "",
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z",
            "category": {
                "id": 1,
                "name": "Coffee"
            },
            "add_ons": [
                {
                    "id": 17,
                    "menu_item_id": 4,
                    "name": "Double Shot for Latte",
                    "description": "Double espresso shot specifically for lattes",
                    "price": 8000,
                    "cogs": 3000,
                    "margin": 62.5,
                    "is_available": true
                },
                {
                    "id": 2,
                    "menu_item_id": null,
                    "name": "Whipped Cream",
                    "description": "Fresh whipped cream",
                    "price": 3000,
                    "cogs": 1500,
                    "margin": 50.0,
                    "is_available": true
                }
            ]
        }
    ]
}
```

**Note:** Menu items now include their associated add-ons (both menu-specific and global add-ons).

### Create Menu Item (Admin/Manager)
```http
POST /api/v1/menu/items
Authorization: Bearer <token>
Content-Type: application/json

{
    "category_id": 1,
    "name": "New Coffee",
    "description": "Delicious new coffee",
    "price": 25000,
    "cogs": 12000,
    "is_available": true
}
```

## Add-ons Management

The system supports both **global add-ons** (available for all menu items) and **menu-specific add-ons** (only available for specific menu items).

### Get All Add-ons
```http
GET /api/v1/add-ons?available=true&menu_item_id=4
```

**Query Parameters:**
- `available` (boolean): Filter by availability status
- `menu_item_id` (integer): Filter by specific menu item ID, or use "global" for global add-ons only

**Response:**
```json
{
    "success": true,
    "data": [
        {
            "id": 1,
            "menu_item_id": null,
            "name": "Extra Shot",
            "description": "Additional espresso shot",
            "price": 8000,
            "cogs": 4000,
            "margin": 50.0,
            "is_available": true,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z"
        },
        {
            "id": 17,
            "menu_item_id": 4,
            "name": "Double Shot for Latte",
            "description": "Double espresso shot specifically for lattes",
            "price": 8000,
            "cogs": 3000,
            "margin": 62.5,
            "is_available": true,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z",
            "menu_item": {
                "id": 4,
                "name": "Latte",
                "price": 28000
            }
        }
    ]
}
```

### Get Add-ons for Specific Menu Item
```http
GET /api/v1/public/menu-item-add-ons/{menu_item_id}
```

Returns both global add-ons and menu-specific add-ons for the given menu item.

**Response:**
```json
{
    "add_ons": [
        {
            "id": 1,
            "menu_item_id": null,
            "name": "Extra Shot",
            "description": "Additional espresso shot",
            "price": 8000,
            "cogs": 4000,
            "margin": 50.0,
            "is_available": true
        },
        {
            "id": 17,
            "menu_item_id": 4,
            "name": "Double Shot for Latte",
            "description": "Double espresso shot specifically for lattes",
            "price": 8000,
            "cogs": 3000,
            "margin": 62.5,
            "is_available": true
        }
    ],
    "menu_item": {
        "id": 4,
        "name": "Latte"
    }
}
```

### Create Add-on (Admin/Manager)
```http
POST /api/v1/add-ons
Authorization: Bearer <token>
Content-Type: application/json
```

**Global Add-on Example:**
```json
{
    "name": "Oat Milk",
    "description": "Premium oat milk substitute",
    "price": 7000,
    "cogs": 4000,
    "is_available": true
}
```

**Menu-Specific Add-on Example:**
```json
{
    "menu_item_id": 4,
    "name": "Latte Art",
    "description": "Beautiful latte art design (only for lattes)",
    "price": 5000,
    "cogs": 0,
    "is_available": true
}
```

### Update Add-on (Admin/Manager)
```http
PUT /api/v1/add-ons/{id}
Authorization: Bearer <token>
Content-Type: application/json

{
    "menu_item_id": 4,
    "name": "Updated Add-on Name",
    "description": "Updated description",
    "price": 6000,
    "cogs": 3000,
    "is_available": true
}
```

### Delete Add-on (Admin/Manager)
```http
DELETE /api/v1/add-ons/{id}
Authorization: Bearer <token>
```

## Transactions

### Customer Name Support
The POS system now supports storing an optional customer name with each transaction. This field:
- Is optional and can be left empty/null
- Accepts any string value (customer's name)
- Is stored with the transaction for future reference
- Can be used for customer service, receipts, or analytics
- Is included in both transaction creation and retrieval endpoints

### Create Transaction
```http
POST /api/v1/transactions
Authorization: Bearer <token>
Content-Type: application/json

{
    "customer_name": "John Doe",
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
    "payment_method": "cash",
    "tax": 2500,
    "discount": 0
}
```

**Request Fields:**
- `customer_name` (string, optional): Customer's name for this transaction
- `items` (array, required): Array of menu items to purchase
- `payment_method` (string, required): Payment method (cash, card, etc.)
- `tax` (number, required): Tax amount in smallest currency unit
- `discount` (number, required): Discount amount in smallest currency unit

**Response:**
```json
{
    "success": true,
    "message": "Transaction created successfully",
    "data": {
        "id": 1,
        "transaction_no": "TXN-20240101-0001",
        "customer_name": "John Doe",
        "status": "pending",
        "payment_method": "cash",
        "sub_total": 46000,
        "tax": 2500,
        "discount": 0,
        "total": 48500,
        "created_at": "2024-01-01T12:00:00Z",
        "items": [
            {
                "id": 1,
                "menu_item_id": 1,
                "quantity": 2,
                "unit_price": 15000,
                "total_price": 30000,
                "menu_item": {
                    "id": 1,
                    "name": "Espresso",
                    "price": 15000
                },
                "add_ons": [
                    {
                        "id": 1,
                        "add_on_id": 1,
                        "quantity": 1,
                        "unit_price": 8000,
                        "total_price": 8000,
                        "add_on": {
                            "id": 1,
                            "name": "Extra Shot",
                            "price": 8000
                        }
                    }
                ]
            }
        ]
    }
}
```

### Process Payment
```http
PUT /api/v1/transactions/1/pay
Authorization: Bearer <token>
Content-Type: application/json

{
    "payment_method": "cash"
}
```

### Get Transactions
```http
GET /api/v1/transactions?status=paid&limit=10&offset=0
Authorization: Bearer <token>
```

**Response:**
```json
{
    "success": true,
    "data": [
        {
            "id": 1,
            "transaction_no": "TXN-20240101-0001",
            "customer_name": "John Doe",
            "status": "paid",
            "payment_method": "cash",
            "sub_total": 46000,
            "tax": 2500,
            "discount": 0,
            "total": 48500,
            "created_at": "2024-01-01T12:00:00Z",
            "updated_at": "2024-01-01T12:30:00Z",
            "items": [
                {
                    "id": 1,
                    "menu_item_id": 1,
                    "quantity": 2,
                    "unit_price": 15000,
                    "total_price": 30000,
                    "menu_item": {
                        "id": 1,
                        "name": "Espresso",
                        "price": 15000
                    },
                    "add_ons": [
                        {
                            "id": 1,
                            "add_on_id": 1,
                            "quantity": 1,
                            "unit_price": 8000,
                            "total_price": 8000,
                            "add_on": {
                                "id": 1,
                                "name": "Extra Shot",
                                "price": 8000
                            }
                        }
                    ]
                }
            ]
        }
    ],
    "pagination": {
        "current_page": 1,
        "per_page": 10,
        "total": 42,
        "total_pages": 5
    }
}
```

### Delete Transaction (Admin/Manager)
```http
DELETE /api/v1/transactions/:id
Authorization: Bearer <token>
```

**Notes:**
- Pending transactions can be deleted by any authenticated user
- Paid transactions can only be deleted by admin users
- Deletes all related transaction items and add-ons

**Response (Success):**
```json
{
    "message": "Transaction deleted successfully"
}
```

**Response (Error - Insufficient Permissions):**
```json
{
    "error": "Only admin can delete paid transactions"
}
```

**Response (Error - Not Found):**
```json
{
    "error": "Transaction not found"
}
```

## Expenses

### Get Expenses
```http
GET /api/v1/expenses?type=raw_material&start_date=2024-01-01&end_date=2024-01-31
Authorization: Bearer <token>
```

**Response:**
```json
{
    "success": true,
    "data": [
        {
            "id": 1,
            "type": "raw_material",
            "category": "Coffee Beans",
            "description": "Premium Arabica coffee beans - 5kg",
            "amount": 500000,
            "date": "2024-01-01T00:00:00Z",
            "user_id": 1,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z",
            "user": {
                "id": 1,
                "username": "admin",
                "role": "admin"
            }
        }
    ]
}
```

### Create Expense (Admin/Manager)
```http
POST /api/v1/expenses
Authorization: Bearer <token>
Content-Type: application/json

{
    "type": "operational",
    "category": "Utilities",
    "description": "Monthly electricity bill",
    "amount": 800000,
    "date": "2024-01-01T00:00:00Z"
}
```

## Dashboard Analytics

### Get Dashboard Stats
```http
GET /api/v1/dashboard/stats?period=monthly
Authorization: Bearer <token>
```

**Response:**
```json
{
    "success": true,
    "data": {
        "total_sales": 5250000,
        "total_transactions": 142,
        "total_expenses": 2100000,
        "profit": 3150000,
        "profit_margin": 60.0,
        "top_selling_items": [
            {
                "menu_item": {
                    "id": 1,
                    "name": "Espresso",
                    "price": 15000
                },
                "total_quantity": 45,
                "total_revenue": 675000
            }
        ],
        "sales_chart": [
            {
                "date": "2024-01-01",
                "sales": 125000,
                "transactions": 8
            }
        ],
        "expense_breakdown": [
            {
                "category": "Raw Materials",
                "amount": 1200000,
                "percentage": 57.14
            }
        ]
    }
}
```

## Payment Methods

### Get Payment Methods
```http
GET /api/v1/payment-methods
```

**Response:**
```json
{
    "success": true,
    "data": [
        {
            "id": 1,
            "name": "Cash",
            "code": "cash",
            "is_active": true
        },
        {
            "id": 2,
            "name": "Credit Card",
            "code": "card",
            "is_active": true
        },
        {
            "id": 3,
            "name": "Digital Wallet",
            "code": "digital_wallet",
            "is_active": true
        }
    ]
}
```

## Error Responses

All endpoints return errors in the following format:

```json
{
    "success": false,
    "message": "Error description",
    "error": "Detailed error information"
}
```

### Common HTTP Status Codes

- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `422` - Validation Error
- `500` - Internal Server Error

## Rate Limiting

The API implements basic rate limiting to prevent abuse. If you exceed the rate limit, you'll receive a `429 Too Many Requests` response.

## CORS

The API supports Cross-Origin Resource Sharing (CORS) for web applications. All origins are allowed in development mode.

## Database Schema Changes

### Add-ons Table Enhancement
The `add_ons` table now includes:
- `menu_item_id` (nullable): Links add-on to specific menu item
- Foreign key constraint to `menu_items` table
- Index on `menu_item_id` for performance

```sql
-- Migration: 005_add_menu_item_id_to_addons.sql
ALTER TABLE add_ons ADD COLUMN menu_item_id INTEGER REFERENCES menu_items(id);
CREATE INDEX idx_add_ons_menu_item_id ON add_ons(menu_item_id);
```

### Data Model Examples

**Global Add-on:**
```json
{
    "id": 2,
    "menu_item_id": null,
    "name": "Whipped Cream",
    "price": 3000,
    "cogs": 1500
}
```

**Menu-Specific Add-on:**
```json
{
    "id": 17,
    "menu_item_id": 4,
    "name": "Double Shot for Latte",
    "price": 8000,
    "cogs": 3000
}
```

### Migration from Old System
Existing add-ons remain unchanged as global add-ons (`menu_item_id: null`). The system is fully backward compatible:

1. **Existing Global Add-ons**: Continue to work for all menu items
2. **New Menu-Specific Add-ons**: Can be created for targeted offerings
3. **API Compatibility**: Old endpoints continue to work as before
4. **UI Enhancement**: Admin interface now shows add-on types with visual indicators

### Best Practices
- Use **global add-ons** for universal options (milk alternatives, sweeteners, temperature preferences)
- Use **menu-specific add-ons** for specialized options (latte art for lattes, extra foam for cappuccinos)
- Consider customer experience when choosing between global vs. specific add-ons

## Testing

You can test the API using tools like:
- **Postman**: Import the collection from `docs/postman/`
- **cURL**: Use the examples above
- **Insomnia**: REST client alternative to Postman

### Testing Menu-Dependent Add-ons

**Test 1: Get add-ons for a specific menu item**
```bash
curl -X GET "http://localhost:8080/api/v1/public/menu-item-add-ons/4"
```

**Test 2: Create a menu-specific add-on**
```bash
curl -X POST "http://localhost:8080/api/v1/add-ons" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "menu_item_id": 4,
    "name": "Extra Foam for Latte",
    "description": "Additional milk foam specifically for lattes",
    "price": 3000,
    "cogs": 1000,
    "is_available": true
  }'
```

**Test 3: Filter add-ons by menu item**
```bash
curl -X GET "http://localhost:8080/api/v1/add-ons?menu_item_id=4"
```

**Test 4: Get only global add-ons**
```bash
curl -X GET "http://localhost:8080/api/v1/add-ons?menu_item_id=global"
```

**Test 5: Get menu items with their add-ons**
```bash
curl -X GET "http://localhost:8080/api/v1/public/menu/items?category_id=1"
```

## Changelog

### Version 2.0 - Menu-Dependent Add-ons (July 2025)

**New Features:**
- ✅ Menu-specific add-ons functionality
- ✅ Global vs. specific add-on categorization
- ✅ Enhanced menu items API with associated add-ons
- ✅ New endpoint: `GET /api/v1/public/menu-item-add-ons/{menu_item_id}`
- ✅ Enhanced filtering: `?menu_item_id=4` and `?menu_item_id=global`
- ✅ Backward compatibility with existing add-ons

**Database Changes:**
- ✅ Added `menu_item_id` column to `add_ons` table
- ✅ Added foreign key constraint and index
- ✅ Migration: `005_add_menu_item_id_to_addons.sql`

**API Enhancements:**
- ✅ Enhanced add-on creation with menu item linking
- ✅ Smart add-on filtering and retrieval
- ✅ Improved response formats with relationship data
- ✅ Better margin calculations and cost analysis

**UI Improvements:**
- ✅ Enhanced admin add-ons management page
- ✅ Visual indicators for global vs. specific add-ons
- ✅ Advanced filtering in admin interface
- ✅ Improved POS system with contextual add-on selection

---
