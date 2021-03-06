﻿
#Область ПрограммныйИнтерфейс

Функция ПолучитьВероятности(НейроннаяСеть, Текст, Параметры = Неопределено) Экспорт
	
	ВидФункцииАктивации = Перечисления.ВидыФункцийАктивацииНейрона.Линейная;
	Если Параметры <> Неопределено Тогда
		Параметры.Свойство("ВидФункцииАктивации", ВидФункцииАктивации);
	КонецЕсли; 
	
	Униграмма = Справочники.Униграммы.ПолучитьУниграммуСтроки(Текст);
	ЭлементыУниграмм = Справочники.Униграммы.НайтиУниграммы(Униграмма);

	Запрос = Новый Запрос;
	Запрос.УстановитьПараметр("НейроннаяСеть", НейроннаяСеть);
	Запрос.УстановитьПараметр("ЭлементыУниграмм", ЭлементыУниграмм);
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	ЭлементыУниграмм.Ссылка КАК Ссылка,
	|	1 КАК Вектор
	|ПОМЕСТИТЬ ВТ_Униграммы
	|ИЗ
	|	&ЭлементыУниграмм КАК ЭлементыУниграмм
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	НейронныеСети.Нейрон КАК Нейрон,
	|	СУММА(НейронныеСети.Вес * ВТ_Униграммы.Вектор) КАК Вероятность
	|ИЗ
	|	РегистрСведений.НейронныеСети КАК НейронныеСети
	|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ ВТ_Униграммы КАК ВТ_Униграммы
	|		ПО НейронныеСети.ВходНейрона = ВТ_Униграммы.Ссылка
	|ГДЕ
	|	НейронныеСети.НейроннаяСеть = &НейроннаяСеть
	|
	|СГРУППИРОВАТЬ ПО
	|	НейронныеСети.Нейрон";
	
	РезультатЗапроса = Запрос.Выполнить();
	
	Если Не РезультатЗапроса.Пустой() Тогда
		
		Результат = РезультатЗапроса.Выгрузить();
		
		Для каждого СтрокаРезультат Из Результат Цикл
			
			СтрокаРезультат.Вероятность = АктивироватьНейрон(СтрокаРезультат.Вероятность, ВидФункцииАктивации);
					
		КонецЦикла;  
		
		Результат.Сортировать("Вероятность Убыв");
		
	КонецЕсли; 
	 
	Возврат Результат;
	
КонецФункции

Процедура ОбучитьНейроннуюСеть(НейроннаяСеть) Экспорт
	
	ДанныеОбучения = НейроннаяСеть.ДанныеОбучения.Получить();
	
	Если ДанныеОбучения = Неопределено Тогда
		Сообщить("Не загружен файл обучения нейронной сети!");
		Возврат;
	КонецЕсли; 
	
	ШагИзмененияВеса = Константы.ШагИзмененияВесаСвязейНейронов.Получить();
	Если Не ЗначениеЗаполнено(ШагИзмененияВеса) Тогда
		Сообщить("Не заполнен шаг изменения веса связей нейронов!");
		Возврат;
	КонецЕсли; 
	
	КоличествоИтерацийОбучения = НейроннаяСеть.КоличествоИтерацийОбучения;
	Если Не ЗначениеЗаполнено(КоличествоИтерацийОбучения) Тогда
		Сообщить("Необходимо, чтобы Количество итераций обучения нейронной сети было больше чем '0'");
		Возврат;
	КонецЕсли;
	
	ЗадатьНачальныеВесаНейроннымСвязям(НейроннаяСеть);
	
	ИмяФайла = ПолучитьИмяВременногоФайла("tmp");
	ДанныеОбучения.Записать(ИмяФайла);
	
	ТекДок = Новый ТекстовыйДокумент;
	ТекДок.Прочитать(ИмяФайла, КодировкаТекста.UTF8);
	
	КоличествоСтрок = ТекДок.КоличествоСтрок();
	
	МенеджерНейронов = Перечисления[ТекДок.ПолучитьСтроку(1)];
	
	Для Итерация = 1 По КоличествоИтерацийОбучения Цикл 
	
		НужноеЗначение = Неопределено;
		
		Для Индекс = 3 По КоличествоСтрок Цикл
			
			ТекСтрока = ТекДок.ПолучитьСтроку(Индекс);
			Если СтрНайти(ТекСтрока, "--------") <> 0 Тогда
				НужноеЗначение = МенеджерНейронов[СтрЗаменить(ТекСтрока, "-", "")];
				Продолжить;
			КонецЕсли;
			
			Если СтрНайти(ТекСтрока, "++++++++") <> 0 Тогда
				Продолжить;
			КонецЕсли; 
			
			Если НужноеЗначение = Неопределено Тогда
				Продолжить;
			КонецЕсли; 
			
			Униграмма = Справочники.Униграммы.ПолучитьУниграммуСтроки(ТекСтрока);
			ЭлементыУниграмм = Справочники.Униграммы.НайтиУниграммы(Униграмма).ВыгрузитьКолонку("Ссылка");
					
			// Получаем текущие вероятности
			Вероятности = ПолучитьВероятности(НейроннаяСеть, ТекСтрока);
			Если Вероятности = Неопределено Тогда
				Сообщить("Необходимо обновить словарь входных параметров нейросети!");
				Возврат;
			КонецЕсли; 
			ВозможныеВероятности = ПолучитьВозможныеВероятности(НейроннаяСеть);
			ПервоеМесто = Вероятности[0].Вероятность;
			ВтороеМесто = Вероятности[1].Вероятность;
			
			// добиваемся правильного значения
			КоэффициентОтклонения = Константы.КоэффициентОтклоненияРезультатаНейроннойСети.Получить();
			
			ТекущееЗначение = Вероятности[0].Нейрон;
					
			Пока ТекущееЗначение <> НужноеЗначение Или (ЗначениеЗаполнено(КоэффициентОтклонения) И СлужебныеПроцедурыКлиентСервер.ABS(ПервоеМесто / ВтороеМесто) < КоэффициентОтклонения) Цикл
				
				Данные = Новый Массив;
							
				Для каждого ТекУниграмма Из ЭлементыУниграмм Цикл
					
					ЭлементДанных = СтруктураДанныхОбновленияСети();
					ЭлементДанных.НейроннаяСеть = НейроннаяСеть;
					ЭлементДанных.ВходНейрона = ТекУниграмма;
					ЭлементДанных.Нейрон = НужноеЗначение;
					ЭлементДанных.Вес = ШагИзмененияВеса;
					Данные.Добавить(ЭлементДанных);
					
					Для каждого ВозможнаяВероятность Из ВозможныеВероятности Цикл
						Если ВозможнаяВероятность.Ключ <> НужноеЗначение Тогда
							ЭлементДанных = СтруктураДанныхОбновленияСети();
							ЭлементДанных.НейроннаяСеть = НейроннаяСеть;
							ЭлементДанных.ВходНейрона = ТекУниграмма;
							ЭлементДанных.Нейрон = ВозможнаяВероятность.Ключ;
							ЭлементДанных.Вес = -ШагИзмененияВеса;
							Данные.Добавить(ЭлементДанных);
						КонецЕсли; 
					КонецЦикла;
					
				КонецЦикла; 
							
				ДобавитьВесНейроннымСвязям(Данные);
				
				Вероятности = ПолучитьВероятности(НейроннаяСеть, ТекСтрока);
				ТекущееЗначение = Вероятности[0].Нейрон;
				ПервоеМесто = Вероятности[0].Вероятность;
				ВтороеМесто = Вероятности[1].Вероятность;
				
			КонецЦикла;  
						 
		КонецЦикла;
	
	КонецЦикла;

	УдалитьФайлы(ИмяФайла);
	
КонецПроцедуры

Функция ПолучитьВозможныеВероятности(НейроннаяСеть) Экспорт
	
	Результат = Новый Соответствие;
	
	Запрос = Новый Запрос;
	Запрос.УстановитьПараметр("НейроннаяСеть", НейроннаяСеть);
	Запрос.Текст = 
	"ВЫБРАТЬ РАЗЛИЧНЫЕ
	|	НейронныеСети.Нейрон КАК Нейрон
	|ИЗ
	|	РегистрСведений.НейронныеСети КАК НейронныеСети
	|ГДЕ
	|	НейронныеСети.НейроннаяСеть = &НейроннаяСеть";
	
	РезультатЗапроса = Запрос.Выполнить();
	Если Не РезультатЗапроса.Пустой() Тогда
		Выборка = РезультатЗапроса.Выбрать();
		Пока Выборка.Следующий() Цикл
			Результат.Вставить(Выборка.Нейрон);	
		КонецЦикла; 
	КонецЕсли; 
	
	Возврат Результат;
	
КонецФункции
 
Процедура ЗадатьНачальныеВесаНейроннымСвязям(НейроннаяСеть) Экспорт
	
	НаборЗаписей = РегистрыСведений.НейронныеСети.СоздатьНаборЗаписей();
	НаборЗаписей.Отбор.НейроннаяСеть.Установить(НейроннаяСеть);
	НаборЗаписей.Прочитать();
	НаборЗаписей.Очистить();
	
	// Входы нейрона
	ИмяМетаданных = Метаданные.НайтиПоТипу(НейроннаяСеть.ВидВходаНейрона.ТипЗначения.Типы()[0]).ПолноеИмя();
	Выборка = СлужебныеПроцедуры.МенеджерОбъектаПоПолномуИмени(ИмяМетаданных).Выбрать();
	
	// нейроны
	ИмяМетаданных = Метаданные.НайтиПоТипу(НейроннаяСеть.ВидНейронов.ТипЗначения.Типы()[0]).ПолноеИмя();
	Менеджер = СлужебныеПроцедуры.МенеджерОбъектаПоПолномуИмени(ИмяМетаданных);
	
	// рандом пока что
	Вес = 0.01;
	
	Пока Выборка.Следующий() Цикл
		
		Для каждого Значение Из Менеджер Цикл
			
			Запись = НаборЗаписей.Добавить();
			Запись.НейроннаяСеть = НейроннаяСеть;
			Запись.ВходНейрона = Выборка.Ссылка;
			Запись.Нейрон = Значение;
			Запись.Вес = Вес;
			
			Вес = Вес + 0.01;
						
		КонецЦикла; 
		
	КонецЦикла; 
	
	НаборЗаписей.Записать();
	
КонецПроцедуры
 
Процедура ДобавитьВесНейроннымСвязям(Данные) Экспорт
	
	Для каждого СтрокаДанные Из Данные Цикл
		
		НаборЗаписей = РегистрыСведений.НейронныеСети.СоздатьНаборЗаписей();
		
		Если СтрокаДанные.НейроннаяСеть <> Неопределено Тогда
			СлужебныеПроцедуры.УстановитьЗначениеОтбора(НаборЗаписей.Отбор.НейроннаяСеть, СтрокаДанные.НейроннаяСеть);
		КонецЕсли;
		
		Если СтрокаДанные.ВходНейрона <> Неопределено Тогда
			СлужебныеПроцедуры.УстановитьЗначениеОтбора(НаборЗаписей.Отбор.ВходНейрона, СтрокаДанные.ВходНейрона);
		КонецЕсли;
		
		Если СтрокаДанные.Нейрон <> Неопределено Тогда
			СлужебныеПроцедуры.УстановитьЗначениеОтбора(НаборЗаписей.Отбор.Нейрон, СтрокаДанные.Нейрон);
		КонецЕсли;
		
		НаборЗаписей.Прочитать();
		
		Для каждого Запись Из НаборЗаписей Цикл
			
			Если СтрокаДанные.Вес >= 0 Или Запись.Вес >= СтрокаДанные.Вес Тогда
				Запись.Вес = Запись.Вес + СтрокаДанные.Вес;
			КонецЕсли; 
			
		КонецЦикла; 
		
		НаборЗаписей.Записать(Истина);
		
	КонецЦикла; 
	
КонецПроцедуры

Процедура ЗаполнитьВекторыСловаря(ИмяОбъектаМетаданных) Экспорт
	
	КоличествоЭлементов = СлужебныеПроцедуры.КоличествоЭлементовТаблицы(ИмяОбъектаМетаданных);
	
	Менеджер = СлужебныеПроцедуры.МенеджерОбъектаПоПолномуИмени(ИмяОбъектаМетаданных);
	
	МетаданныеОбъекта = Менеджер.ПолучитьСсылку().Метаданные();
	Если МетаданныеОбъекта.Реквизиты.Найти("Вектор") = Неопределено Тогда
		Возврат;
	КонецЕсли; 
	
	Выборка = Менеджер.Выбрать();
	Индекс = 1;
	
	Пока Выборка.Следующий() Цикл
		
		СпрОбъект = Выборка.ПолучитьОбъект();
		СпрОбъект.Вектор = Индекс / КоличествоЭлементов;
		СпрОбъект.Записать();
		
		Индекс = Индекс + 1;
		
	КонецЦикла;
	
КонецПроцедуры
 
#КонецОбласти

#Область СлужебныеПроцедурыИФункции
 
Функция АктивироватьНейрон(Значение, ВидФункцииАктивации)
	
	Если ВидФункцииАктивации = Перечисления.ВидыФункцийАктивацииНейрона.Линейная Тогда
		Возврат Значение;
	ИначеЕсли ВидФункцииАктивации = Перечисления.ВидыФункцийАктивацииНейрона.Сигмоида Тогда
		Возврат 1/(1 + Exp(-Значение));
	ИначеЕсли ВидФункцииАктивации = Перечисления.ВидыФункцийАктивацииНейрона.ГиперболическийТангенс Тогда
		Возврат (Exp(Значение) - Exp(-Значение)) / (Exp(Значение) + Exp(-Значение));
	КонецЕсли; 
	
КонецФункции

Функция СтруктураДанныхОбновленияСети()
	
	Возврат Новый Структура("НейроннаяСеть,Нейрон,ВходНейрона,Вес");
	
КонецФункции

#КонецОбласти

 
 