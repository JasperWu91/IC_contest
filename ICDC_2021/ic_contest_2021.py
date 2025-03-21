import math

def cross_product(p0, p1, p2):
    ax = p1[0] - p0[0]
    ay = p1[1] - p0[1]
    bx = p2[0] - p0[0]
    by = p2[1] - p0[1]
    cross = ax * by - bx * ay
    print(f"Cross product between {p1} and {p2} relative to {p0}: {cross}")
    return cross

def sort_vertices(receivers):
    print("\n=== Sorting Receivers ===")
    origin = receivers[0]
    print(f"Chosen origin: {origin}")
    

    def key_func(p):
        dx = p[0] - origin[0]
        dy = p[1] - origin[1]
        angle = math.atan2(dy, dx)
        distance = dx**2 + dy**2
        print(f"Point {p}: Angle = {angle:.4f}, Distance = {distance}")
        return (angle, distance)
    
    sorted_receivers = sorted(receivers[1:], key=key_func)
    result = [origin] + sorted_receivers
    print(f"Sorted vertices (counter-clockwise): {result}")
    return result

def polygon_area(vertices):
    print("\n=== Calculating Polygon Area ===")
    n = len(vertices)
    area = 0
    print("Using Shoelace Formula:")
    for i in range(n):
        j = (i + 1) % n
        term1 = vertices[i][0] * vertices[j][1]
        term2 = vertices[j][0] * vertices[i][1]
        area += term1 - term2
        print(f"Edge {i} to {j}: ({vertices[i]} -> {vertices[j]})")
        print(f"  {vertices[i][0]} * {vertices[j][1]} - {vertices[j][0]} * {vertices[i][1]} = {term1} - {term2} = {term1 - term2}")
    area = abs(area) / 2
    print(f"Total Polygon Area: {area}")
    return area

def triangle_area(p1, p2, p3):
    print(f"Triangle ({p1}, {p2}, {p3}):")
    area = abs((p1[0] * (p2[1] - p3[1]) + p2[0] * (p3[1] - p1[1]) + p3[0] * (p1[1] - p2[1])) / 2)
    print(f"  Area = |({p1[0]} * ({p2[1]} - {p3[1]}) + {p2[0]} * ({p3[1]} - {p1[1]}) + {p3[0]} * ({p1[1]} - {p2[1]}))| / 2 = {area}")
    return area
    
def is_point_inside(point, vertices):
    print(f"\n=== Checking if Point {point} is Inside ===")
    poly_area = polygon_area(vertices)
    total_triangle_area = 0
    print("\nCalculating sum of triangle areas formed by point and vertices:")
    for i in range(len(vertices)):
        j = (i + 1) % len(vertices)
        tri_area = triangle_area(point, vertices[i], vertices[j])
        total_triangle_area += tri_area
    
    print(f"\nPolygon Area: {poly_area}")
    print(f"Sum of Triangle Areas: {total_triangle_area}")
    tolerance = 1e-6
    is_inside = abs(total_triangle_area - poly_area) < tolerance
    print(f"Difference: {abs(total_triangle_area - poly_area)} < {tolerance} -> {'Inside' if is_inside else 'Outside'}")
    return is_inside


receivers = [
    (103, 340),  # O/6
    (755, 510),   # O/38
    (103, 50),  # O/4
    (982, 280),  # O/2
    (290, 560),  # O/2 
    (710, 50)   # O/2 
]

test_points = [
    (381, 12), (161, 720), (343, 840), (444, 647) 
]


def main():

    sorted_receivers = sort_vertices(receivers)

    for idx, point in enumerate(test_points, 1):
        print(f"\n===== Testing Point {idx}: {point} =====")
        result = is_point_inside(point, sorted_receivers)
        print(f"Final Result for Point {point}: {'Inside' if result else 'Outside'}\n{'='*50}")

if __name__ == "__main__":
    main()



