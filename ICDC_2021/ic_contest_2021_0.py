import matplotlib.pyplot as plt
import math

# x = [103, 755, 103, 982, 298, 710]
# y = [340, 510, 50, 280, 560, 50]
# R = [350, 345, 553,616, 122, 549]
# R = [118, 252,567, 763,559, 294]
# R = [350, 122, 345,616, 549, 553]

# x = [103, 755, 103, 982, 298, 710]
# y = [340, 510, 50, 280, 560, 50]

# points = [(300, 800), (710, 620), (980, 120),  (400, 80),  (130,210 ) ,(103, 500)]
# R = [659, 732, 840, 272, 50, 342]

#================================================================================================


x = [302, 694,  694 , 503, 43, 10]
y = [423 , 768 ,1023 , 521, 1003, 664]
points = [(43,1003 ),  (694, 1023), (694, 768), (503, 521),  (302,423),    (10, 664)]
R = [322, 630, 546, 394, 315, 146]
plt.scatter(x, y, color='blue', marker='o')

for (x_coord, y_coord) in points:
    plt.annotate(f'({x_coord}, {y_coord})', 
                 (x_coord, y_coord), 
                 xytext=(5, 5), 
                 textcoords='offset points')

plt.xlabel('X axis')
plt.ylabel('Y axis')
plt.title('Scatter Plot of Points with Coordinates')

plt.grid(True)

plt.margins(0.1)

plt.show()


#================================================================================================
x = [302, 694,  694 , 503, 43, 10]
y = [423 , 768 ,1023 , 521, 1003, 664]
points = [(43,1003 ),  (694, 1023), (694, 768), (503, 521),  (302,423),    (10, 664)]
R = [322, 630, 546, 394, 315, 146]

total_length = 0

side_length = []
print("\n=== Calculating side length ===")
for i in range(len(points)):
    x1, y1 = points[i]
    x2, y2 = points[(i + 1) % len(points)] 
    length = math.sqrt((x2 - x1)**2 + (y2 - y1)**2)
    print(f"邊 {i+1}: 從 {points[i]} 到 {points[(i + 1) % len(points)]} = {length:.2f}\n")
    side_length.append(length)
    total_length += length


total_area = 0
for i in range(len(points)):
    idx = (i + 1) % len(points)
    print(f"a1:{side_length[i]:.2f},  a2:{R[i]}, a3:{R[idx]}\n")
    s = (side_length[i] + R[i] + R[idx]) / 2
    print(f"S ={s:.2f}\n")
    area = math.sqrt(s * (s - side_length[i]) * (s - R[i]) * (s - R[idx]))
    print(f"Area {i+1}: 從 {points[i]} 到 {points[(i + 1) % len(points)]} = {area:.2f}")
    total_area += area

print(f"\n Total area = {total_area:.2f}")


# 計算多邊形面積（鞋帶公式）
def polygon_area(points):
    n = len(points)
    area = 0
    print("\n=== Calculating Polygon Area ===\n")
    print("Using Shoelace Formula:")
    for i in range(n):
        j = (i + 1) % n
        term1 = points[i][0] * points[j][1]
        term2 = points[j][0] * points[i][1]
        area += term1 - term2
        print(f"Edge {i} to {j}: ({points[i]} -> {points[j]})")
        print(f"  {points[i][0]} * {points[j][1]} - {points[j][0]} * {points[i][1]} = {term1} - {term2} = {term1 - term2}")
    area = abs(area) / 2
    print(f"Total Polygon Area: {area:.2f}")
    return area

# 計算並印出多邊形面積
area = polygon_area(points)
print(f"\nFinal Polygon Area = {area:.2f}")