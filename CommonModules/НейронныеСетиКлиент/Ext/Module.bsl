﻿
#Область ПрограммныйИнтерфейс

Процедура НачатьОбучениеНейроннойСети(Форма, НейроннаяСеть) Экспорт
	
	Если Форма.Модифицированность Тогда
		Сообщить("Сначала запишите справочник!");
		Возврат;
	КонецЕсли; 
	
	НейронныеСетиВызовСервера.ОбучитьНейроннуюСеть(НейроннаяСеть);
	
КонецПроцедуры

#КонецОбласти


 