# moneybot
Управление телеграм ботом на встроенном языке 1С Предприятие 8.3. Постановка задачи - создание быстрого и легкого способа управления семейным бюджетом.

Описание обучения нейронныхсетей:
В системе созданы предопределенные элементы справочника нейронных сетей (для определения типа операции, вида денежных средств и т.д.), а также предопределенные словари.
Любую нейронную сеть необходимо сначала обучить. Порядок действия обучения:
1. В элементе справочника нейронных сетей необходимо ввести вид входов нейронных сетей (как правило, это униграммы), а также вид нейронов (одно из перечислений). Если быть точным, то это планы видов характеристик.
2. Необходимо заполнить всевозможные входные нейроны.
  2.1 Определение типа входного нейрона. Тип = Ссылка.ВидВходаНейрона.ТипЗначения.Типы()[0]. Заходим в этот справочник, нажимаем в форме списка кнопку "Добавить из нейронной сети", выбираем нужную сеть.
3. В справочнике нейронной сети заполняем количество итераций обучения. Как правило 10 - 15 итераций хватает за глаза.
4. Заполняем коэффициент отклонения результата. При вычислении вероятностей первый результат должен иметь большее отклонение от второго результата. Таким обраазом при обучении ПервыйРезультат / ВторойРезультат > КоэффициентОтклонения.
5. Нажимаем в элементе нейронной сети кнопку в командной панели "Обучить нейроннуюсеть". Ждём.
6. Для всех остальных нейросетей проделываем то же самое.
ПРИМЕЧАНИЕ:
При желании можно создать нейронную сеть вручную. Пример файла обучения нейросети можно найти в общих макетах. Первая строка - тип значения нейроной, вторая строка - тип значения входов нейрона. Строка, окруженная знаками ------- - значение нейрона.
