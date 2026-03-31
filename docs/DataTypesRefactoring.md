# Проблема після останніх доданих тобою змін (останній комміт)

Використовуй це для побудови плану

To obtain values from an .a7p profile in the desired units, you need to divide them by the multiplier.
For the reverse operation, you need to perform the inverse operation and convert to an integer.

| key                      | unit           | multiplier | desc                                        |
|--------------------------|----------------|------------|---------------------------------------------|
| sc_height                | mm             | 1          | sight height in mm                          |
| r_twist                  | inch           | 100        | positive twist value                        |
| c_zero_temperature       | C              | 1          | temperature at c_muzzle_velocity            |
| c_muzzle_velocity        | mps            | 10         | muzzle velocity at c_zero_temperature       |
| c_t_coeff                | %/15C          | 1000       | temperature sensitivity                     |
| c_zero_distance_idx      | <int>          | 10         | index of zero distance from distances table |
| c_zero_air_temperature   | C              | 1          | air temperature at zero                     |
| c_zero_air_pressure      | hPa            | 10         | air pressure at zero                        |
| c_zero_air_humidity      | %              | 1          | air humidity at zero                        |
| c_zero_p_temperature     | C              | 1          | powder temperature at zero                  |
| c_zero_w_pitch           | deg            | 1          | zeroing look angle                          |
| b_diameter               | inch           | 1000       | bullet diameter                             |
| b_weight                 | grain          | 10         | bullet weight                               |
| b_length                 | inch           | 1000       | bullet length                               |
| twist_dir                | RIGHT\|LEFT    |            | twist direction                             |
| bc_type                  | G1\|G7\|CUSTOM |            | g-func type                                 |
| distances                | m              | 100        | distances table in m                        |
| zero_x                   | <int>          | -1000      | zeroing h-clicks for specific device        |
| zero_y                   | <int>          | 1000       | zeroing v-clicks for specific device        |
| coef_rows.bc_cd (G1/G7)  |                | 10000      | bc coefficient for mv                       |
| coef_rows.mv    (G1/G7)  | mps            | 10         | mv for bc provided                          |
| coef_rows.bc_cd (CUSTOM) |                | 10000      | drag coefficient (Cd)                       |
| coef_rows.mv    (CUSTOM) | mach           | 10         | speed in mach                               |

Також використовуй схему валідації описану тут
https://raw.githubusercontent.com/o-murphy/a7p/refs/heads/master/src/a7p/yupy_schema.py
Або тут
https://raw.githubusercontent.com/o-murphy/a7p-js/refs/heads/master/src/validate.ts

## Найважливіше: 

### Phase 1 - виправити плутатина в drag model
    1. драг модель має будуватись тільки для розрахунку а не бути контейнером даних - це тільки runtime об'єкт, всі дані мають залишатись в Projectile
    2. По друге DragModelType має містити тільки g1, g7, custom
    3. Окремого поля bc в Projectile бути не має, балістичні дані зберігаються у coefRows а визначення чи це multibc - окремий геттер Projectile.isMultiBC - логіку 
       * g1 or g7 && coefRows.length <= 1 --> значить беремо tableG1/tableG7 + перетворюємо coefRows.first.bc_cd на bc - DragModel(bc, tableG1/tableG7), якщо bc_cd == 0 -> bc == 1  
       * custom && coefRows.length > 1 --> значить маємо кастомну таблицю і розраховуємо bc - DragModel(calculated_bc or 0, customTableFromCoefCows) 
       * g1 or g7 && coefRows.length > 1 --> значить беремо tableG1/tableG7 + перетворюємо coefRows на мультибк - createDragModelMultiBC()
    4. Projectile має отримати метод toDragModel()
    5. Збереження даних в json і відновлення в форматі Projectile (НЕ DragModel)

### Phase 2 - Виправити моделі екранів які було зламано відповідно до оновлених структур даних.

### Phase 3 - те саме стосується Weapon, Ammo, Conditions, Wind
вони мають бути тільки рантайм об'єктами солвера - окремий рівень абстракції! + методи конвертації у відповідних Rifle, Cartridge, etc. Тобто шар solver має бути максимально відокремлений від стану віджетів чи стореджа, він має тільки формувати дані для розрахунку і надавати деякі методи для виклику

