export function validateEmail(email: string): boolean {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
}

export function validatePassword(password: string): boolean {
    return password.length >= 6; // Example: Password must be at least 6 characters long
}

export function validateProductName(name: string): boolean {
    return name.length > 0; // Example: Product name cannot be empty
}

export function validateOrderQuantity(quantity: number): boolean {
    return quantity > 0; // Example: Quantity must be greater than 0
}