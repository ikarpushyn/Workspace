score = 0

knight = {
    x = 100,
    y = 200,
    speed = 200,
    health = 150,
    radius = 100,
    sprite = love.graphics.newImage("assets/sprites/knight.png")
}
target = {
    size = 20,
    x = math.random(50, love.graphics.getWidth() - 50),
    y = math.random(50, love.graphics.getHeight() - 50)
}

function love.load() -- Инициализация ресурсов
    -- Загрузка спрайтов, звуков
end

function love.update(dt) -- Обновление логики (dt = время с последнего кадра)
    -- Движение юнитов, таймеры

    -- тест управление на стрелочки 
    if love.keyboard.isDown("right") then
        knight.x = knight.x + knight.speed * dt
    end
    if love.keyboard.isDown("left") then
        knight.x = knight.x - knight.speed * dt
    end
    if love.keyboard.isDown("down") then
        knight.y = knight.y + knight.speed * dt
    end
    if love.keyboard.isDown("up") then
        knight.y = knight.y - knight.speed * dt
    end

    -- Проверка столкновения игрока с целью
    local dx = knight.x - target.x
    local dy = knight.y - target.y
    local distance = math.sqrt(dx * dx + dy * dy)

    if distance < knight.radius + target.size / 2 then
        score = score + 1
        -- Перемещаем цель в случайное место
        target.x = math.random(50, love.graphics.getWidth() - 50)
        target.y = math.random(50, love.graphics.getHeight() - 50)
    end

end

function love.draw() -- Отрисовка
    -- Рисуем фон, юнитов, UI

    -- Выводим счёт
    love.graphics.print("Count: " .. score, 10, 10)

    -- Рисуем игрока (knight)
    love.graphics.draw(knight.sprite, knight.x, knight.y)

    -- Рисуем цель (красный квадрат)
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", target.x - target.size / 2, target.y - target.size / 2, target.size, target.size)

    -- Сбрасываем цвет для остальных элементов
    love.graphics.setColor(1, 1, 1)

end

